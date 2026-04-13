import logging
import os
import uuid
import datetime
import asyncio
import shutil

from app import models, database, schemas
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form, Header, Request
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from passlib.context import CryptContext
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import google.generativeai as genai
from dotenv import load_dotenv
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("shoes_store")

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
load_dotenv()
ADMIN_SECRET_KEY = os.getenv("ADMIN_SECRET_KEY", "")
if not ADMIN_SECRET_KEY:
    logger.warning("ADMIN_SECRET_KEY tidak di-set! Endpoint admin tidak terproteksi.")

GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model_ai = genai.GenerativeModel('gemini-1.5-flash')
    logger.info("Gemini AI model loaded.")
else:
    model_ai = None
    logger.warning("GOOGLE_API_KEY tidak ditemukan, chatbot fallback ke mode keyword.")

# ---------------------------------------------------------------------------
# File upload validation
# ---------------------------------------------------------------------------
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB

async def read_and_validate_image(file: UploadFile) -> bytes:
    """Baca file upload, validasi tipe MIME dan ukuran. Raise HTTPException jika invalid."""
    content_type = file.content_type or ""

    # Normalisasi: image/jpg → image/jpeg (non-standard tapi umum dikirim Android)
    if content_type == "image/jpg":
        content_type = "image/jpeg"

    # Fallback: inferensi dari ekstensi filename jika content_type hilang atau generik
    if content_type not in ALLOWED_IMAGE_TYPES:
        ext = os.path.splitext(file.filename or "")[1].lower()
        ext_map = {
            ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
            ".png": "image/png", ".gif": "image/gif", ".webp": "image/webp",
        }
        content_type = ext_map.get(ext, content_type)

    if content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Format file tidak valid. Hanya JPEG, PNG, GIF, WEBP yang diizinkan. Diterima: {file.content_type}"
        )

    content = await file.read()
    if len(content) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Ukuran file terlalu besar (maksimal 5MB).")
    return content

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title="Shoes Store API - Real E-commerce Engine")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

models.Base.metadata.create_all(bind=database.engine)

os.makedirs("uploads", exist_ok=True)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/management", StaticFiles(directory="admin_panel", html=True), name="admin")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Helper: enrich order items dengan data produk
# ---------------------------------------------------------------------------
def _enrich_order_items(orders):
    """Konversi list ORM Order ke list dict dengan product info di tiap item."""
    result = []
    for order in orders:
        order_dict = {
            "id": order.id,
            "user_id": order.user_id,
            "total": order.total,
            "unique_code": order.unique_code,
            "status": order.status,
            "tanggal": order.tanggal,
            "expired_at": order.expired_at,
            "shipping_address": order.shipping_address,
            "phone": order.phone,
            "payment": None,
            "items": [],
        }

        if order.payment:
            order_dict["payment"] = {
                "id": order.payment.id,
                "order_id": order.payment.order_id,
                "proof_image_url": order.payment.proof_image_url,
                "status": order.payment.status,
                "uploaded_at": order.payment.uploaded_at,
            }

        for item in order.items:
            item_dict = {
                "id": item.id,
                "sku_id": item.sku_id,
                "quantity": item.quantity,
                "price_at_checkout": item.price_at_checkout,
                "product_id": None,
                "product_name": None,
                "product_image": None,
                "variant_name": None,
            }
            if item.sku and item.sku.product:
                item_dict["product_id"] = item.sku.product.id
                item_dict["product_name"] = item.sku.product.name
                item_dict["product_image"] = item.sku.product.image
                item_dict["variant_name"] = item.sku.variant_name
            order_dict["items"].append(item_dict)

        result.append(order_dict)
    return result


# ---------------------------------------------------------------------------
# Background Worker — Auto-cancel UNPAID orders
# ---------------------------------------------------------------------------
async def auto_cancel_orders_worker():
    while True:
        db = None
        try:
            db = database.SessionLocal()
            now = datetime.datetime.utcnow()
            expired_orders = db.query(models.Order).filter(
                models.Order.status == "UNPAID",
                models.Order.expired_at < now
            ).all()

            if expired_orders:
                for order in expired_orders:
                    order.status = "CANCELLED"
                    for item in order.items:
                        if item.sku_id:
                            sku = db.query(models.ProductSku).filter(
                                models.ProductSku.id == item.sku_id
                            ).first()
                            if sku:
                                sku.stock_available += item.quantity
                                sku.stock_reserved -= item.quantity
                db.commit()
                logger.info(f"Auto-cancel: {len(expired_orders)} order dibatalkan dan stok dikembalikan.")

        except Exception as e:
            logger.error(f"Background worker error: {e}", exc_info=True)
            if db:
                try:
                    db.rollback()
                except Exception:
                    pass
        finally:
            if db:
                db.close()

        await asyncio.sleep(60)


@app.on_event("startup")
async def startup_event():
    models.Base.metadata.create_all(bind=database.engine)
    asyncio.create_task(auto_cancel_orders_worker())
    logger.info("Shoes Store API started. Background worker aktif.")


# ---------------------------------------------------------------------------
# Auth Dependencies
# ---------------------------------------------------------------------------
def get_current_user(authorization: str = Header(None)) -> str:
    """Ekstrak dan validasi username dari Bearer token."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization header diperlukan. Format: 'Bearer <token>'")
    token = authorization[7:]
    if not token.startswith("token-rahasia-"):
        raise HTTPException(status_code=401, detail="Token tidak valid")
    username = token[len("token-rahasia-"):]
    if not username:
        raise HTTPException(status_code=401, detail="Token tidak valid atau sudah kedaluwarsa")
    return username


def verify_admin(x_admin_key: str = Header(None)) -> None:
    """Validasi X-Admin-Key header untuk endpoint admin."""
    if not ADMIN_SECRET_KEY:
        # Dev mode: admin key tidak dikonfigurasi, akses admin diizinkan tanpa auth
        return
    if not x_admin_key or x_admin_key != ADMIN_SECRET_KEY:
        raise HTTPException(status_code=403, detail="Akses ditolak. Admin key tidak valid.")


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------
@app.post("/login")
@limiter.limit("10/minute")
def login_with_json(request: Request, user_data: schemas.UserLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if not user:
        user = db.query(models.User).filter(models.User.email == user_data.username).first()
    if not user or not pwd_context.verify(user_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Username atau password salah!")
    return {
        "access_token": f"token-rahasia-{user.username}",
        "token_type": "bearer",
        "username": user.username,
        "email": user.email
    }

@app.post("/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email terdaftar!")
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username terdaftar!")

    hashed_pwd = pwd_context.hash(user.password)
    new_user = models.User(username=user.username, email=user.email, hashed_password=hashed_pwd)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    logger.info(f"User baru terdaftar: {user.username}")
    return new_user

@app.get("/users/{username}", response_model=schemas.UserResponse)
def get_user_profile(username: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    return user


# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
@app.get("/products", response_model=List[schemas.ProductResponse])
def get_all_products(db: Session = Depends(database.get_db)):
    return db.query(models.Product).all()

@app.post("/products", response_model=schemas.ProductResponse)
def create_product(product: schemas.ProductCreate, db: Session = Depends(database.get_db)):
    new_product = models.Product(
        name=product.name, price=product.price, description=product.description,
        image=product.image, category=product.category, rating=product.rating
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)

    for sku_data in product.skus:
        sku = models.ProductSku(
            product_id=new_product.id,
            variant_name=sku_data.variant_name,
            price=sku_data.price,
            stock_available=sku_data.stock_available,
            stock_reserved=sku_data.stock_reserved
        )
        db.add(sku)

    for clr in product.colors:
        color_entry = models.ProductColor(product_id=new_product.id, color_hex=clr.color_hex)
        db.add(color_entry)

    db.commit()
    db.refresh(new_product)
    logger.info(f"Produk baru dibuat: {new_product.name} (id={new_product.id})")
    return new_product


# ---------------------------------------------------------------------------
# Cart
# ---------------------------------------------------------------------------
@app.get("/cart", response_model=schemas.CartResponse)
def get_cart(username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    cart = db.query(models.Cart).filter(models.Cart.user_id == user.id).first()
    if not cart:
        cart = models.Cart(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart

@app.post("/cart", tags=["Cart"])
def upsert_cart_item(item: schemas.CartItemAdd, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    """Menambah barang ke keranjang (dengan validasi stok real-time)"""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    cart = db.query(models.Cart).filter(models.Cart.user_id == user.id).first()
    if not cart:
        cart = models.Cart(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)

    if item.quantity < 1:
        raise HTTPException(status_code=400, detail="Quantity minimal 1.")

    sku = db.query(models.ProductSku).filter(models.ProductSku.id == item.sku_id).first()
    if not sku:
        raise HTTPException(status_code=404, detail="SKU tidak ditemukan")

    existing_item = db.query(models.CartItem).filter(
        models.CartItem.cart_id == cart.id,
        models.CartItem.sku_id == item.sku_id
    ).first()

    # Hitung total quantity yang akan ada di keranjang setelah operasi ini
    current_qty = existing_item.quantity if existing_item else 0
    new_total_qty = current_qty + item.quantity

    if sku.stock_available < new_total_qty:
        raise HTTPException(
            status_code=400,
            detail=f"Gagal! Stok {sku.variant_name} tidak cukup. Tersedia: {sku.stock_available}, di keranjang: {current_qty}"
        )

    if existing_item:
        existing_item.quantity = new_total_qty
    else:
        new_item = models.CartItem(cart_id=cart.id, sku_id=item.sku_id, quantity=item.quantity)
        db.add(new_item)

    db.commit()
    return {"message": "Berhasil masuk keranjang"}

@app.put("/cart/{cart_item_id}", tags=["Cart"])
def update_cart_item_quantity(
    cart_item_id: int,
    quantity: int,
    username: str = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """Set cart item ke quantity tertentu (>= 1). Gunakan DELETE untuk menghapus."""
    if quantity < 1:
        raise HTTPException(status_code=400, detail="Quantity minimal 1. Gunakan DELETE untuk menghapus item.")

    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    cart = db.query(models.Cart).filter(models.Cart.user_id == user.id).first()
    if not cart:
        raise HTTPException(status_code=404, detail="Keranjang tidak ditemukan")

    item = db.query(models.CartItem).filter(
        models.CartItem.id == cart_item_id,
        models.CartItem.cart_id == cart.id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item tidak ada di keranjang")

    sku = db.query(models.ProductSku).filter(models.ProductSku.id == item.sku_id).first()
    if not sku:
        raise HTTPException(status_code=404, detail="SKU tidak ditemukan")

    if sku.stock_available < quantity:
        raise HTTPException(
            status_code=400,
            detail=f"Stok tidak mencukupi. Tersedia: {sku.stock_available}"
        )

    item.quantity = quantity
    db.commit()
    return {"message": "Quantity berhasil diupdate", "quantity": quantity}


@app.delete("/cart/{cart_item_id}", tags=["Cart"])
def remove_cart_item(cart_item_id: int, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    """Hapus satu item dari keranjang secara permanen"""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    cart = db.query(models.Cart).filter(models.Cart.user_id == user.id).first()
    if not cart:
        raise HTTPException(status_code=404, detail="Keranjang tidak ditemukan")

    item = db.query(models.CartItem).filter(
        models.CartItem.id == cart_item_id,
        models.CartItem.cart_id == cart.id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item tidak ada di keranjang")

    db.delete(item)
    db.commit()
    return {"message": "Item berhasil dihapus dari keranjang"}


# ---------------------------------------------------------------------------
# Checkout
# ---------------------------------------------------------------------------
@app.post("/checkout", response_model=schemas.OrderResponse, tags=["Transaction Logic"])
def checkout_cart(payload: schemas.OrderCreate, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    """Logika Transaksional Shopee: Lock Stock, Kalkulasi Ulang, Batas Waktu"""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    if not payload.items:
        raise HTTPException(status_code=400, detail="Tidak ada barang dipilih")

    try:
        order_id = str(uuid.uuid4())[:8].upper()
        unique_code = sum([ord(c) for c in user.username]) % 100 + 1  # 1-100, agar tidak terlalu besar

        new_order = models.Order(
            id=order_id,
            user_id=user.id,
            total=0.0,
            unique_code=unique_code,
            status="UNPAID",
            expired_at=datetime.datetime.utcnow() + datetime.timedelta(hours=24),
            shipping_address=payload.address,
            phone=payload.phone
        )
        db.add(new_order)

        calculated_total = 0.0
        cart = db.query(models.Cart).filter(models.Cart.user_id == user.id).first()

        for item in payload.items:
            sku = db.query(models.ProductSku).filter(
                models.ProductSku.id == item.sku_id
            ).with_for_update().first()

            if not sku or sku.stock_available < item.quantity:
                raise HTTPException(
                    status_code=400,
                    detail="Oops! Ada barang yang kehabisan stok. Silakan cek keranjang."
                )

            calculated_total += sku.price * item.quantity

            sku.stock_available -= item.quantity
            sku.stock_reserved += item.quantity

            order_item = models.OrderItem(
                order_id=order_id,
                sku_id=item.sku_id,
                quantity=item.quantity,
                price_at_checkout=sku.price
            )
            db.add(order_item)

            if cart:
                db.query(models.CartItem).filter(
                    models.CartItem.cart_id == cart.id,
                    models.CartItem.sku_id == item.sku_id
                ).delete()

        new_order.total = calculated_total + unique_code

        log = models.TransactionLog(
            user_id=user.id,
            action="CHECKOUT",
            details=f"Checkout {len(payload.items)} item ke {payload.address}"
        )
        db.add(log)

        db.commit()
        db.refresh(new_order)
        logger.info(f"Checkout berhasil: order {order_id} oleh user {username}")
        return new_order

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Checkout error untuk user {username}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal memproses checkout. Silakan coba lagi.")


# ---------------------------------------------------------------------------
# Orders
# ---------------------------------------------------------------------------
@app.get("/orders", response_model=List[schemas.OrderResponse])
def get_order_history(username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    orders = db.query(models.Order).filter(models.Order.user_id == user.id).all()
    return _enrich_order_items(orders)


# ---------------------------------------------------------------------------
# Payment Upload & Admin Approval
# ---------------------------------------------------------------------------
@app.post("/orders/{order_id}/pay")
async def upload_payment_proof(
    order_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db)
):
    """User mengupload bukti transfer manual"""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order or order.status != "UNPAID":
        raise HTTPException(status_code=400, detail="Order tidak valid atau sudah dibayar")

    content = await read_and_validate_image(file)

    # Gunakan UUID agar nama file tidak bisa diprediksi
    ext = os.path.splitext(file.filename or "image.jpg")[1] or ".jpg"
    safe_filename = f"payment_{order_id}_{uuid.uuid4().hex}{ext}"
    file_path = f"uploads/{safe_filename}"

    try:
        with open(file_path, "wb") as buffer:
            buffer.write(content)
    except Exception as e:
        logger.error(f"Gagal menulis file payment {order_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal menyimpan file.")

    payment = models.PaymentConfirmation(order_id=order_id, proof_image_url=file_path)
    db.add(payment)
    order.status = "VERIFYING"
    db.commit()
    logger.info(f"Bukti pembayaran diunggah untuk order {order_id}")
    return {"message": "Bukti berhasil diunggah, menunggu verifikasi Admin!"}


@app.put("/orders/{order_id}/received", tags=["Transaction Logic"])
def confirm_order_received(
    order_id: str,
    username: str = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """Customer mengkonfirmasi paket sudah diterima (SHIPPED → DELIVERED)"""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    order = db.query(models.Order).filter(
        models.Order.id == order_id,
        models.Order.user_id == user.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order tidak ditemukan")
    if order.status != "SHIPPED":
        raise HTTPException(status_code=400, detail="Pesanan belum dalam status pengiriman")

    order.status = "DELIVERED"
    db.commit()
    logger.info(f"Order {order_id} dikonfirmasi diterima oleh user {username}")
    return {"message": "Pesanan dikonfirmasi diterima!", "status": "DELIVERED"}


@app.get("/admin/orders", response_model=List[schemas.OrderResponse], tags=["Admin"])
def admin_get_all_orders(_: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Dashboard Admin memantau seluruh transaksi"""
    orders = db.query(models.Order).all()
    return _enrich_order_items(orders)


@app.put("/admin/orders/{order_id}/status", tags=["Admin"])
def admin_update_order_status(
    order_id: str,
    payload: schemas.OrderStatusUpdate,
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin Approve/Reject Pesanan dan Update Stok Akhir"""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order tidak ditemukan")

    try:
        if payload.status == "PAID" and order.status == "VERIFYING":
            for item in order.items:
                sku = db.query(models.ProductSku).filter(
                    models.ProductSku.id == item.sku_id
                ).first()
                if sku:
                    sku.stock_reserved -= item.quantity
            logger.info(f"Order {order_id} diapprove oleh admin.")

        elif payload.status == "REJECTED" and order.status == "VERIFYING":
            payload.status = "CANCELLED"
            for item in order.items:
                sku = db.query(models.ProductSku).filter(
                    models.ProductSku.id == item.sku_id
                ).first()
                if sku:
                    sku.stock_reserved -= item.quantity
                    sku.stock_available += item.quantity
            logger.info(f"Order {order_id} ditolak admin, stok dikembalikan.")

        order.status = payload.status
        db.commit()
        db.refresh(order)

        enriched = _enrich_order_items([order])
        return enriched[0]

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Admin update order {order_id} error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal mengupdate status order.")


@app.put("/admin/skus/{sku_id}/stock", tags=["Admin"])
def admin_update_sku_stock(sku_id: int, stock: int, _: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin update stok produk secara manual"""
    sku = db.query(models.ProductSku).filter(models.ProductSku.id == sku_id).first()
    if not sku:
        raise HTTPException(status_code=404, detail="SKU tidak ditemukan")
    sku.stock_available = stock
    db.commit()
    logger.info(f"Stok SKU {sku_id} diupdate ke {stock} oleh admin.")
    return {"status": "success", "new_stock": stock}


@app.post("/admin/products/{product_id}/image", tags=["Admin"])
async def admin_upload_product_image(
    product_id: int,
    file: UploadFile = File(...),
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin upload/ganti foto produk."""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")

    content = await read_and_validate_image(file)
    ext = os.path.splitext(file.filename or ".jpg")[1] or ".jpg"
    safe_filename = f"product_{product_id}_{uuid.uuid4().hex}{ext}"
    file_path = f"uploads/{safe_filename}"

    try:
        with open(file_path, "wb") as buffer:
            buffer.write(content)
    except Exception as e:
        logger.error(f"Gagal menyimpan foto produk {product_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal menyimpan file.")

    product.image = file_path
    db.commit()
    logger.info(f"Foto produk {product_id} diupdate: {file_path}")
    return {"message": "Foto berhasil diupdate", "image_url": f"/{file_path}"}


@app.delete("/admin/products/{product_id}", tags=["Admin"])
def admin_delete_product(product_id: int, _: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin menghapus produk"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    db.delete(product)
    db.commit()
    logger.info(f"Produk {product_id} dihapus oleh admin.")
    return {"status": "deleted"}


@app.put("/admin/products/{product_id}", tags=["Admin"])
def admin_update_product(
    product_id: int,
    payload: schemas.ProductUpdate,
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin edit info produk (nama, harga, deskripsi, kategori)"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")

    if payload.name is not None:
        product.name = payload.name
    if payload.price is not None:
        product.price = payload.price
    if payload.description is not None:
        product.description = payload.description
    if payload.category is not None:
        product.category = payload.category

    db.commit()
    db.refresh(product)
    logger.info(f"Produk {product_id} diupdate oleh admin.")
    return product


@app.post("/admin/products/{product_id}/skus", tags=["Admin"])
def admin_add_sku(
    product_id: int,
    payload: schemas.ProductSkuCreate,
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin tambah varian ukuran baru ke produk"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")

    new_sku = models.ProductSku(
        product_id=product_id,
        variant_name=payload.variant_name,
        price=payload.price,
        stock_available=payload.stock_available,
        stock_reserved=payload.stock_reserved,
    )
    db.add(new_sku)
    db.commit()
    db.refresh(new_sku)
    logger.info(f"SKU baru ditambahkan ke produk {product_id}: {payload.variant_name}")
    return new_sku


@app.delete("/admin/skus/{sku_id}", tags=["Admin"])
def admin_delete_sku(sku_id: int, _: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin hapus varian ukuran produk"""
    sku = db.query(models.ProductSku).filter(models.ProductSku.id == sku_id).first()
    if not sku:
        raise HTTPException(status_code=404, detail="SKU tidak ditemukan")
    db.delete(sku)
    db.commit()
    logger.info(f"SKU {sku_id} dihapus oleh admin.")
    return {"status": "deleted"}


@app.get("/admin/users", tags=["Admin"])
def admin_get_users(_: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin lihat semua pengguna terdaftar"""
    users = db.query(models.User).all()
    result = []
    for user in users:
        order_count = db.query(models.Order).filter(models.Order.user_id == user.id).count()
        total_spent = db.query(models.Order).filter(
            models.Order.user_id == user.id,
            models.Order.status.in_(["PAID", "SHIPPED", "COMPLETED", "DELIVERED"])
        ).all()
        spent = sum(o.total for o in total_spent)
        result.append({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "profile_image": user.profile_image,
            "order_count": order_count,
            "total_spent": spent,
        })
    return result


# ---------------------------------------------------------------------------
# Favorites
# ---------------------------------------------------------------------------
@app.post("/favorites", response_model=schemas.FavoriteResponse)
def toggle_favorite(fav: schemas.FavoriteCreate, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    existing = db.query(models.Favorite).filter(
        models.Favorite.user_id == user.id,
        models.Favorite.product_id == fav.product_id
    ).first()
    if existing:
        db.delete(existing)
        db.commit()
        return {"id": existing.id, "user_id": user.id, "product_id": fav.product_id}
    new_fav = models.Favorite(user_id=user.id, product_id=fav.product_id)
    db.add(new_fav)
    db.commit()
    db.refresh(new_fav)
    return new_fav

@app.get("/favorites", response_model=List[schemas.ProductResponse])
def get_user_favorites(username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    return db.query(models.Product).join(
        models.Favorite, models.Product.id == models.Favorite.product_id
    ).filter(models.Favorite.user_id == user.id).all()


# ---------------------------------------------------------------------------
# Chatbot
# ---------------------------------------------------------------------------
@app.post("/chat", response_model=schemas.ChatResponse)
def chat_with_bot(request: schemas.ChatRequest):
    msg = request.message.lower()
    if model_ai:
        try:
            context = "Kamu adalah Sneakerhead Assistant dari toko Shoes Store. Jawab ramah dan profesional. "
            response = model_ai.generate_content(context + msg)
            return {"reply": response.text}
        except Exception as e:
            logger.warning(f"Gemini AI error, fallback ke keyword: {e}")

    if "promo" in msg or "diskon" in msg:
        reply = "Tentu! Saat ini ada promo diskon 20% untuk semua koleksi Jordan. Gunakan kode: SHOES20."
    elif "stok" in msg or "ready" in msg:
        reply = "Kami memakai sistem Live Stock! Barang yang bisa masuk keranjang pasti Ready."
    else:
        reply = "Untuk order, tambahkan ke keranjang lalu lengkapi pembayaran. Akan divalidasi admin."
    return {"reply": reply}


# ---------------------------------------------------------------------------
# Addresses
# ---------------------------------------------------------------------------
@app.get("/addresses", response_model=List[schemas.AddressResponse], tags=["Address"])
def get_addresses(username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    return db.query(models.Address).filter(models.Address.user_id == user.id).all()

@app.post("/addresses", response_model=schemas.AddressResponse, tags=["Address"])
def add_address(payload: schemas.AddressCreate, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    if payload.is_default:
        db.query(models.Address).filter(
            models.Address.user_id == user.id
        ).update({"is_default": False})

    new_addr = models.Address(**payload.model_dump(), user_id=user.id)
    db.add(new_addr)
    db.add(models.TransactionLog(user_id=user.id, action="CREATE_ADDRESS", details="Saved a new address"))
    db.commit()
    db.refresh(new_addr)
    return new_addr

@app.put("/addresses/{address_id}", response_model=schemas.AddressResponse, tags=["Address"])
def update_address(address_id: str, payload: schemas.AddressBase, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    addr = db.query(models.Address).filter(
        models.Address.id == address_id,
        models.Address.user_id == user.id
    ).first()
    if not addr:
        raise HTTPException(status_code=404, detail="Alamat tidak ditemukan")
    if payload.is_default:
        db.query(models.Address).filter(
            models.Address.user_id == user.id,
            models.Address.id != address_id
        ).update({"is_default": False})
    addr.label = payload.label
    addr.receiver_name = payload.receiver_name
    addr.phone_number = payload.phone_number
    addr.full_address = payload.full_address
    addr.is_default = payload.is_default
    db.commit()
    db.refresh(addr)
    logger.info(f"Alamat {address_id} diupdate oleh {username}")
    return addr


@app.delete("/addresses/{address_id}", tags=["Address"])
def delete_address(address_id: str, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    addr = db.query(models.Address).filter(
        models.Address.id == address_id,
        models.Address.user_id == user.id
    ).first()
    if addr:
        db.delete(addr)
        db.add(models.TransactionLog(user_id=user.id, action="DELETE_ADDRESS", details="Deleted an address"))
        db.commit()
    return {"status": "ok"}


# ---------------------------------------------------------------------------
# Reviews
# ---------------------------------------------------------------------------
def _enrich_review(review, db: Session) -> dict:
    """Tambahkan username ke dict review."""
    user = db.query(models.User).filter(models.User.id == review.user_id).first()
    return {
        "id": review.id,
        "product_id": review.product_id,
        "user_id": review.user_id,
        "username": user.username if user else "Anonim",
        "rating": review.rating,
        "comment": review.comment,
        "image_path": review.image_path,
        "date": review.date,
    }


@app.get("/reviews/{product_id}", tags=["Review"])
def get_product_reviews(product_id: int, db: Session = Depends(database.get_db)):
    reviews = db.query(models.Review).filter(
        models.Review.product_id == product_id
    ).order_by(models.Review.date.desc()).all()
    return [_enrich_review(r, db) for r in reviews]


@app.post("/reviews", tags=["Review"])
async def add_review(
    username: str = Depends(get_current_user),
    id: str = Form(...),
    product_id: int = Form(...),
    rating: float = Form(...),
    comment: str = Form(None),
    file: UploadFile = File(None),
    db: Session = Depends(database.get_db)
):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    # Satu user hanya bisa review 1x per produk
    existing = db.query(models.Review).filter(
        models.Review.product_id == product_id,
        models.Review.user_id == user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Kamu sudah memberikan ulasan untuk produk ini. Gunakan fitur edit untuk mengubah ulasanmu.")

    image_path_saved = None
    if file and file.filename:
        content = await read_and_validate_image(file)
        filename = f"review_{uuid.uuid4().hex}{os.path.splitext(file.filename or '.jpg')[1]}"
        filepath = f"uploads/{filename}"
        try:
            with open(filepath, "wb") as buffer:
                buffer.write(content)
            image_path_saved = filepath
        except Exception as e:
            logger.error(f"Gagal menyimpan gambar review: {e}", exc_info=True)

    try:
        new_rev = models.Review(
            id=id,
            product_id=product_id,
            user_id=user.id,
            rating=rating,
            comment=comment,
            image_path=image_path_saved
        )
        db.add(new_rev)
        db.add(models.TransactionLog(
            user_id=user.id,
            action="ADD_REVIEW",
            details=f"Review untuk produk {product_id}"
        ))
        db.commit()
        db.refresh(new_rev)
        return _enrich_review(new_rev, db)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Gagal menyimpan review ke DB: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Gagal menyimpan review: {str(e)}")


@app.put("/reviews/{review_id}", tags=["Review"])
async def update_review(
    review_id: str,
    username: str = Depends(get_current_user),
    rating: float = Form(...),
    comment: str = Form(None),
    file: UploadFile = File(None),
    db: Session = Depends(database.get_db)
):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    review = db.query(models.Review).filter(
        models.Review.id == review_id,
        models.Review.user_id == user.id
    ).first()
    if not review:
        raise HTTPException(status_code=404, detail="Ulasan tidak ditemukan atau bukan milikmu")

    if file and file.filename:
        content = await read_and_validate_image(file)
        filename = f"review_{uuid.uuid4().hex}{os.path.splitext(file.filename or '.jpg')[1]}"
        filepath = f"uploads/{filename}"
        try:
            with open(filepath, "wb") as buffer:
                buffer.write(content)
            review.image_path = filepath
        except Exception as e:
            logger.error(f"Gagal update gambar review: {e}", exc_info=True)

    review.rating = rating
    review.comment = comment
    db.commit()
    db.refresh(review)
    logger.info(f"Review {review_id} diupdate oleh {username}")
    return _enrich_review(review, db)


@app.delete("/reviews/{review_id}", tags=["Review"])
def delete_review(review_id: str, username: str = Depends(get_current_user), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    review = db.query(models.Review).filter(
        models.Review.id == review_id,
        models.Review.user_id == user.id
    ).first()
    if not review:
        raise HTTPException(status_code=404, detail="Ulasan tidak ditemukan atau bukan milikmu")
    db.delete(review)
    db.commit()
    logger.info(f"Review {review_id} dihapus oleh {username}")
    return {"status": "ok"}


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------
@app.post("/profile/update", tags=["Profile"])
async def update_profile(
    username: str = Depends(get_current_user),
    email: str = Form(...),
    password: str = Form(None),
    file: UploadFile = File(None),
    db: Session = Depends(database.get_db)
):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    user.email = email
    if password:
        user.hashed_password = pwd_context.hash(password)

    if file and file.filename:
        content = await read_and_validate_image(file)
        ext = os.path.splitext(file.filename or ".jpg")[1] or ".jpg"
        filename = f"profile_{uuid.uuid4().hex}{ext}"
        filepath = f"uploads/{filename}"
        try:
            with open(filepath, "wb") as buffer:
                buffer.write(content)
            user.profile_image = filepath
        except Exception as e:
            logger.error(f"Gagal menyimpan foto profil: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Gagal menyimpan foto profil.")

    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email sudah digunakan oleh pengguna lain")

    return {
        "message": "Profile updated",
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "profile_image": f"/{user.profile_image}" if user.profile_image else None
        }
    }


# ---------------------------------------------------------------------------
# Promos
# ---------------------------------------------------------------------------
@app.get("/promos", response_model=List[schemas.PromoResponse], tags=["Promo"])
def get_promos(db: Session = Depends(database.get_db)):
    """Mendapatkan daftar promo banner home."""
    return db.query(models.PromoBanner).filter(models.PromoBanner.is_active == True).all()
