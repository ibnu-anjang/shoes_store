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
from sqlalchemy import text
from typing import List, Optional
from passlib.context import CryptContext
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
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

# Migration: tambah kolom baru jika belum ada
with database.engine.connect() as _conn:
    for col_sql in [
        "ALTER TABLE orders ADD COLUMN subtotal FLOAT NULL",
        "ALTER TABLE orders ADD COLUMN shipped_at DATETIME NULL",
        "ALTER TABLE orders ADD COLUMN payment_method VARCHAR(20) NULL",
        "ALTER TABLE orders ADD COLUMN tracking_number VARCHAR(100) NULL",
        "ALTER TABLE product_colors ADD COLUMN image_url VARCHAR(255) NULL",
        "ALTER TABLE product_images ADD COLUMN color_hex VARCHAR(50) NULL",
    ]:
        try:
            _conn.execute(text(col_sql))
            _conn.commit()
        except Exception:
            pass

# Seed default payment config jika belum ada
_PAYMENT_DEFAULTS = {
    "tf_bank_name":       "BCA (Modern Shoes Store)",
    "tf_account_number":  "7712 8890 1234",
    "tf_account_holder":  "PT Shoes Store Modern",
    "qris_image":         "",   # path relatif dari /uploads/
}
with database.SessionLocal() as _sess:
    for k, v in _PAYMENT_DEFAULTS.items():
        if not _sess.get(models.SiteSetting, k):
            _sess.add(models.SiteSetting(key=k, value=v))
    _sess.commit()

os.makedirs("uploads", exist_ok=True)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/management", StaticFiles(directory="admin_panel", html=True), name="admin")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,  # Harus False jika allow_origins=["*"]; app pakai Bearer token, bukan cookie
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Helper: enrich order items dengan data produk
# ---------------------------------------------------------------------------
def _enrich_order_items(orders, user_id: int = None, db: Session = None):
    """Konversi list ORM Order ke list dict dengan product info di tiap item.

    Jika user_id dan db diberikan, reviewed_item_ids diisi berdasarkan review
    yang sudah dikirim user tersebut untuk tiap order_item.
    """
    result = []
    for order in orders:
        reviewed_item_ids: list = []
        if user_id and db:
            reviewed_item_ids = [
                r.order_item_id
                for r in db.query(models.Review).filter(
                    models.Review.user_id == user_id,
                    models.Review.order_item_id.in_([i.id for i in order.items]),
                ).all()
                if r.order_item_id is not None
            ]

        order_dict = {
            "id": order.id,
            "user_id": order.user_id,
            "username": order.user.username if order.user else None,
            "email": order.user.email if order.user else None,
            "profile_image": order.user.profile_image if order.user else None,
            "total": order.total,
            "subtotal": order.subtotal,
            "unique_code": order.unique_code,
            "status": order.status,
            "tanggal": order.tanggal,
            "expired_at": order.expired_at,
            "shipped_at": order.shipped_at,
            "payment_method": order.payment_method,
            "tracking_number": order.tracking_number,
            "shipping_address": order.shipping_address,
            "phone": order.phone,
            "payment": None,
            "items": [],
            "reviewed_item_ids": reviewed_item_ids,
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
                "color_hex": item.color_hex,
                "product_id": None,
                "product_name": None,
                "product_image": None,
                "variant_name": None,
            }
            if item.sku and item.sku.product:
                product = item.sku.product
                item_dict["product_id"] = product.id
                item_dict["product_name"] = product.name
                item_dict["variant_name"] = item.sku.variant_name
                
                # Logic: Search gallery for color-specific image
                color_image = None
                if item.color_hex:
                    # Find image in gallery that matches the color_hex
                    for gallery_img in product.gallery:
                        if gallery_img.color_hex == item.color_hex:
                            color_image = gallery_img.image_url
                            break
                
                # Fallback to main product image if no color-specific image found
                item_dict["product_image"] = color_image if color_image else product.image
                
            order_dict["items"].append(item_dict)

        result.append(order_dict)
    return result


# ---------------------------------------------------------------------------
# Background Worker — Auto-cancel UNPAID orders
# ---------------------------------------------------------------------------
def _return_stock_for_order(order, db: Session):
    """Kembalikan stok untuk semua item di order (dipakai saat cancel)."""
    for item in order.items:
        if item.sku_id:
            sku = db.query(models.ProductSku).filter(models.ProductSku.id == item.sku_id).first()
            if sku:
                sku.stock_available += item.quantity
                sku.stock_reserved = max(0, sku.stock_reserved - item.quantity)


async def auto_cancel_orders_worker():
    while True:
        db = None
        try:
            db = database.SessionLocal()
            now = datetime.datetime.utcnow()

            # Auto-cancel UNPAID dan VERIFYING yang melewati expired_at
            expired_orders = db.query(models.Order).filter(
                models.Order.status.in_(["UNPAID", "VERIFYING"]),
                models.Order.expired_at < now
            ).all()
            for order in expired_orders:
                order.status = "CANCELLED"
                _return_stock_for_order(order, db)
            if expired_orders:
                db.commit()
                logger.info(f"Auto-cancel: {len(expired_orders)} order dibatalkan.")

            # Auto-complete SHIPPED yang sudah > 24 jam sejak dikirim
            shipped_cutoff = now - datetime.timedelta(hours=24)
            shipped_orders = db.query(models.Order).filter(
                models.Order.status == "SHIPPED",
                models.Order.shipped_at != None,
                models.Order.shipped_at < shipped_cutoff
            ).all()
            for order in shipped_orders:
                order.status = "DELIVERED"
                for item in order.items:
                    if item.sku_id:
                        sku = db.query(models.ProductSku).filter(models.ProductSku.id == item.sku_id).first()
                        if sku:
                            sku.stock_reserved = max(0, sku.stock_reserved - item.quantity)
            if shipped_orders:
                db.commit()
                logger.info(f"Auto-complete: {len(shipped_orders)} order otomatis selesai.")

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
        logger.warning(f"Login gagal: {user_data.username} dari IP {request.client.host}")
        raise HTTPException(status_code=400, detail="Username atau password salah!")
    logger.info(f"User login: {user.username} dari IP {request.client.host}")
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

@app.get("/products/search", response_model=schemas.PaginatedProductResponse)
def search_products(
    q: Optional[str] = None,
    category: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(database.get_db),
):
    query = db.query(models.Product).filter(models.Product.is_active == True)
    if q:
        query = query.filter(models.Product.name.ilike(f"%{q}%"))
    if category and category != "All":
        query = query.filter(models.Product.category == category)
    total = query.count()
    pages = max(1, -(-total // limit))  # ceiling division
    items = query.offset((page - 1) * limit).limit(limit).all()
    return {"items": items, "total": total, "page": page, "pages": pages}

@app.get("/categories", response_model=List[str])
def get_categories(db: Session = Depends(database.get_db)):
    rows = db.query(models.Product.category).filter(
        models.Product.is_active == True,
        models.Product.category != None,
        models.Product.category != "",
    ).distinct().all()
    return sorted([r[0] for r in rows])

@app.post("/products", response_model=schemas.ProductResponse)
def create_product(product: schemas.ProductCreate, db: Session = Depends(database.get_db)):
    new_product = models.Product(
        name=product.name, price=product.price, description=product.description,
        specification=product.specification,
        image=product.image, category=product.category, rating=product.rating
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)

    # Add gallery images
    for img_url in product.gallery:
        if img_url:
            db.add(models.ProductImage(product_id=new_product.id, image_url=img_url))

    for sku_data in product.skus:
        sku = models.ProductSku(
            product_id=new_product.id,
            variant_name=sku_data.variant_name,
            color_hex=sku_data.color_hex,
            price=sku_data.price,
            stock_available=sku_data.stock_available,
            stock_reserved=sku_data.stock_reserved
        )
        db.add(sku)

    for clr in product.colors:
        color_entry = models.ProductColor(product_id=new_product.id, color_hex=clr.color_hex, image_url=clr.image_url)
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
        models.CartItem.sku_id == item.sku_id,
        models.CartItem.color_hex == item.color_hex
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
        if item.color_hex:
            existing_item.color_hex = item.color_hex
    else:
        new_item = models.CartItem(
            cart_id=cart.id, 
            sku_id=item.sku_id, 
            quantity=item.quantity,
            color_hex=item.color_hex
        )
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
        is_cod = payload.payment_method.upper() == 'COD'

        # COD: tidak pakai kode unik, langsung diproses
        unique_code = 0 if is_cod else (sum([ord(c) for c in user.username]) % 100 + 1)
        initial_status = "PAID" if is_cod else "UNPAID"

        new_order = models.Order(
            id=order_id,
            user_id=user.id,
            total=0.0,
            unique_code=unique_code,
            status=initial_status,
            payment_method=payload.payment_method.upper(),
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
                price_at_checkout=sku.price,
                color_hex=item.color_hex
            )
            db.add(order_item)

            if cart:
                db.query(models.CartItem).filter(
                    models.CartItem.cart_id == cart.id,
                    models.CartItem.sku_id == item.sku_id
                ).delete()

        new_order.subtotal = calculated_total
        new_order.total = calculated_total if is_cod else calculated_total + unique_code

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
    return _enrich_order_items(orders, user_id=user.id, db=db)


# ---------------------------------------------------------------------------
# Payment Upload & Admin Approval
# ---------------------------------------------------------------------------
@app.post("/orders/{order_id}/pay")
async def upload_payment_proof(
    order_id: str,
    file: UploadFile = File(...),
    username: str = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """User mengupload bukti transfer manual (TF/QRIS only)"""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    order = db.query(models.Order).filter(
        models.Order.id == order_id,
        models.Order.user_id == user.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order tidak ditemukan")
    if order.payment_method == 'COD':
        raise HTTPException(status_code=400, detail="Order COD tidak memerlukan bukti pembayaran.")
    if order.status not in ("UNPAID", "VERIFYING"):
        raise HTTPException(status_code=400, detail="Order tidak valid atau sudah diproses")

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


@app.post("/orders/{order_id}/cancel", tags=["Transaction Logic"])
def cancel_order(
    order_id: str,
    username: str = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """User membatalkan pesanan (hanya boleh jika status UNPAID atau VERIFYING)."""
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    order = db.query(models.Order).filter(
        models.Order.id == order_id,
        models.Order.user_id == user.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order tidak ditemukan")

    if order.status not in ("UNPAID", "VERIFYING", "PAID"):
        raise HTTPException(status_code=400, detail="Pesanan tidak dapat dibatalkan pada status ini.")

    try:
        order.status = "CANCELLED"
        _return_stock_for_order(order, db)
        db.add(models.TransactionLog(
            user_id=user.id,
            action="ORDER_CANCELLED",
            details=f"Order {order_id} dibatalkan oleh user"
        ))
        db.commit()
        logger.info(f"Order {order_id} dibatalkan oleh user {username}")
        return {"message": "Pesanan berhasil dibatalkan.", "status": "CANCELLED"}
    except Exception as e:
        db.rollback()
        logger.error(f"Cancel order {order_id} error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal membatalkan pesanan.")


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
                    sku.stock_reserved = max(0, sku.stock_reserved - item.quantity)
            logger.info(f"Order {order_id} diapprove oleh admin.")

        elif payload.status == "REJECTED" and order.status == "VERIFYING":
            # Kembalikan stok dan biarkan user re-upload bukti (set ke UNPAID)
            if order.payment:
                db.delete(order.payment)
            payload.status = "UNPAID"
            logger.info(f"Order {order_id} ditolak admin, stok dikembalikan, user bisa re-upload.")

        elif payload.status == "SHIPPED" and order.status in ("PAID",):
            order.shipped_at = datetime.datetime.utcnow()
            if payload.tracking_number:
                order.tracking_number = payload.tracking_number.strip()
            # Kurangi stock_reserved karena barang sudah benar-benar dikirim
            for item in order.items:
                sku = db.query(models.ProductSku).filter(
                    models.ProductSku.id == item.sku_id
                ).first()
                if sku:
                    sku.stock_reserved = max(0, sku.stock_reserved - item.quantity)
            logger.info(f"Order {order_id} dikirim (SHIPPED), resi: {payload.tracking_number}.")

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


@app.put("/admin/skus/{sku_id}", tags=["Admin"])
def admin_update_sku(
    sku_id: int, 
    stock: Optional[int] = None, 
    price: Optional[float] = None, 
    color_hex: Optional[str] = None,
    _: None = Depends(verify_admin), 
    db: Session = Depends(database.get_db)
):
    """Admin update detail SKU secara manual (stok, harga, warna)"""
    sku = db.query(models.ProductSku).filter(models.ProductSku.id == sku_id).first()
    if not sku:
        raise HTTPException(status_code=404, detail="SKU tidak ditemukan")
    
    if stock is not None:
        sku.stock_available = stock
    if price is not None:
        sku.price = price
    if color_hex is not None:
        sku.color_hex = color_hex if color_hex != 'null' else None

    db.commit()
    logger.info(f"SKU {sku_id} diupdate oleh admin: Stok={stock}, Harga={price}, Warna={color_hex}")
    return {"status": "success", "sku_id": sku_id}


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

@app.post("/admin/products/{product_id}/colors/{color_hex}/image", tags=["Admin"])
async def admin_upload_color_image(
    product_id: int,
    color_hex: str,
    file: UploadFile = File(...),
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin upload image for specific color. color_hex should be e.g. 0xFF000000"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")

    h = color_hex
    if not h.startswith("0xFF"):
        h = "0xFF" + h.replace("#", "").upper()
        
    color_record = db.query(models.ProductColor).filter(
        models.ProductColor.product_id == product_id, 
        models.ProductColor.color_hex == h
    ).first()
    
    if not color_record:
        raise HTTPException(status_code=404, detail="Warna tidak ditemukan di produk ini")

    content = await read_and_validate_image(file)
    ext = os.path.splitext(file.filename or ".jpg")[1] or ".jpg"
    safe_filename = f"color_{product_id}_{uuid.uuid4().hex[:8]}{ext}"
    file_path = f"uploads/{safe_filename}"

    try:
        with open(file_path, "wb") as buffer:
            buffer.write(content)
    except Exception as e:
        logger.error(f"Gagal menyimpan foto warna {product_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal menyimpan file.")

    color_record.image_url = file_path
    db.commit()
    return {"message": "Foto warna diupdate", "image_url": f"/{file_path}"}


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
    if payload.specification is not None:
        product.specification = payload.specification
    
    if payload.colors is not None:
        # Ganti semua warna yang ada dengan list yang baru
        db.query(models.ProductColor).filter(models.ProductColor.product_id == product_id).delete()
        for c in payload.colors:
            db.add(models.ProductColor(product_id=product_id, color_hex=c.color_hex, image_url=c.image_url))

    if payload.skus is not None:
        for s_data in payload.skus:
            if s_data.id:
                # Update existing SKU
                sku = db.query(models.ProductSku).filter(models.ProductSku.id == s_data.id).first()
                if sku:
                    if s_data.variant_name is not None: sku.variant_name = s_data.variant_name
                    if s_data.color_hex is not None: sku.color_hex = s_data.color_hex if s_data.color_hex != 'null' else None
                    if s_data.price is not None: sku.price = s_data.price
                    if s_data.stock_available is not None: sku.stock_available = s_data.stock_available
            else:
                # Add new SKU if ID is missing (though usually handled elsewhere)
                new_sku = models.ProductSku(
                    product_id=product_id,
                    variant_name=s_data.variant_name or "Default",
                    color_hex=s_data.color_hex if s_data.color_hex != 'null' else None,
                    price=s_data.price or product.price,
                    stock_available=s_data.stock_available or 0,
                    stock_reserved=0
                )
                db.add(new_sku)

    if payload.gallery is not None:
        for img_data in payload.gallery:
            img = db.query(models.ProductImage).filter(models.ProductImage.id == img_data.id).first()
            if img:
                img.color_hex = img_data.color_hex if img_data.color_hex != 'null' else None

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
        color_hex=payload.color_hex,
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


@app.delete("/admin/orders/{order_id}", tags=["Admin"])
def admin_delete_order(order_id: str, _: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin hapus pesanan beserta relasinya"""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order tidak ditemukan")
    db.delete(order)
    db.commit()
    logger.info(f"Order {order_id} dihapus oleh admin.")
    return {"status": "deleted"}


@app.delete("/admin/users/{user_id}", tags=["Admin"])
def admin_delete_user(user_id: int, _: None = Depends(verify_admin), db: Session = Depends(database.get_db)):
    """Admin hapus pengguna beserta relasinya"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    db.query(models.Cart).filter(models.Cart.user_id == user_id).delete()
    db.query(models.Favorite).filter(models.Favorite.user_id == user_id).delete()
    db.query(models.Address).filter(models.Address.user_id == user_id).delete()
    db.query(models.Review).filter(models.Review.user_id == user_id).delete()
    db.query(models.TransactionLog).filter(models.TransactionLog.user_id == user_id).delete()
    
    orders = db.query(models.Order).filter(models.Order.user_id == user_id).all()
    for o in orders:
        db.delete(o)
        
    db.delete(user)
    db.commit()
    logger.info(f"User {user_id} dihapus oleh admin.")
    return {"status": "deleted"}


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
def chat_with_bot(request: schemas.ChatRequest, db: Session = Depends(database.get_db)):
    from app.ollama_service import OllamaService

    product_context = ""
    msg_lower = request.message.lower()
    keywords = ["stok", "stock", "ada", "tersedia", "harga", "price", "ukuran", "size", "produk", "sepatu", "nike", "adidas", "vans", "converse"]
    if any(k in msg_lower for k in keywords):
        products = db.query(models.Product).filter(models.Product.is_active == True).limit(20).all()
        if products:
            lines = []
            for p in products:
                skus = db.query(models.ProductSku).filter(models.ProductSku.product_id == p.id).all()
                sku_info = ", ".join(
                    f"{s.variant_name} (stok: {s.stock_available}, harga: Rp{int(s.price):,})"
                    for s in skus if s.stock_available > 0
                ) or "stok habis"
                lines.append(f"- {p.name} | {p.category or 'sepatu'} | {sku_info}")
            product_context = "\n".join(lines)

    reply = OllamaService.generate_chat(request.message, product_context)
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
def _recalculate_product_rating(product_id: int, db: Session):
    reviews = db.query(models.Review).filter(models.Review.product_id == product_id).all()
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if product:
        product.rating = round(sum(r.rating for r in reviews) / len(reviews), 1) if reviews else 0.0

def _enrich_review(review, db: Session) -> dict:
    """Tambahkan username dan profile_picture ke dict review."""
    user = db.query(models.User).filter(models.User.id == review.user_id).first()
    profile_pic = None
    if user and user.profile_image:
        img = user.profile_image
        if img.startswith('http'):
            profile_pic = img
        elif img.startswith('/'):
            profile_pic = img
        elif img.startswith('uploads/'):
            profile_pic = f"/{img}"
        else:
            profile_pic = f"/uploads/{img}"
    return {
        "id": review.id,
        "product_id": review.product_id,
        "user_id": review.user_id,
        "username": user.username if user else "Anonim",
        "rating": review.rating,
        "comment": review.comment,
        "image_path": review.image_path,
        "profile_picture": profile_pic,
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
    order_item_id: int = Form(...),
    rating: float = Form(...),
    comment: str = Form(None),
    file: UploadFile = File(None),
    db: Session = Depends(database.get_db)
):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")

    # Satu user hanya bisa review 1x per order_item (bukan per produk)
    existing = db.query(models.Review).filter(
        models.Review.order_item_id == order_item_id,
        models.Review.user_id == user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Kamu sudah memberikan ulasan untuk pembelian ini.")

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
            order_item_id=order_item_id,
            user_id=user.id,
            rating=rating,
            comment=comment,
            image_path=image_path_saved
        )
        db.add(new_rev)
        db.add(models.TransactionLog(
            user_id=user.id,
            action="ADD_REVIEW",
            details=f"Review untuk produk {product_id} (order_item {order_item_id})"
        ))
        db.flush()
        _recalculate_product_rating(product_id, db)
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
    db.flush()
    _recalculate_product_rating(review.product_id, db)
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
    product_id = review.product_id
    db.delete(review)
    db.flush()
    _recalculate_product_rating(product_id, db)
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

@app.post("/admin/promos", tags=["Admin"])
async def admin_add_promo(
    files: List[UploadFile] = File(...),
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin upload promo banner baru (multiple files)"""
    new_promos = []
    
    for file in files:
        content = await file.read()
        if len(content) > 5 * 1024 * 1024:
            continue
        
        ext = os.path.splitext(file.filename or ".jpg")[1] or ".jpg"
        safe_filename = f"promo_{uuid.uuid4().hex[:8]}{ext}"
        file_path = f"/uploads/{safe_filename}"
        full_path = f"uploads/{safe_filename}"
        
        with open(full_path, "wb") as f:
            f.write(content)
            
        promo = models.PromoBanner(image_url=file_path, is_active=True)
        db.add(promo)
        new_promos.append(promo)
        
    db.commit()
    for p in new_promos:
        db.refresh(p)
    return new_promos


@app.delete("/admin/promos/{promo_id}", tags=["Admin"])
def admin_delete_promo(
    promo_id: int,
    _: None = Depends(verify_admin),
    db: Session = Depends(database.get_db)
):
    """Admin hapus promo banner"""
    promo = db.query(models.PromoBanner).filter(models.PromoBanner.id == promo_id).first()
    if not promo:
        raise HTTPException(status_code=404, detail="Promo tidak ditemukan")
    
    # Hapus file fisik jika ada
    if promo.image_url:
        path = promo.image_url.lstrip("/")
        if os.path.exists(path):
            try: os.remove(path)
            except: pass
        
    db.delete(promo)
    db.commit()
    return {"message": "Promo berhasil dihapus"}

# ---------------------------------------------------------------------------
# Payment Config (info TF & QRIS, bisa diedit lewat admin panel)
# ---------------------------------------------------------------------------
@app.get("/payment-config", tags=["Payment Config"])
def get_payment_config(db: Session = Depends(database.get_db)):
    """Kembalikan semua setting pembayaran sebagai dict key→value."""
    rows = db.query(models.SiteSetting).all()
    return {r.key: r.value for r in rows}

@app.put("/admin/payment-config", tags=["Payment Config"])
def update_payment_config(
    payload: dict,
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin),
):
    """Update info bank TF (tf_bank_name, tf_account_number, tf_account_holder)."""
    allowed = {"tf_bank_name", "tf_account_number", "tf_account_holder"}
    for key, value in payload.items():
        if key not in allowed:
            continue
        row = db.get(models.SiteSetting, key)
        if row:
            row.value = str(value)
        else:
            db.add(models.SiteSetting(key=key, value=str(value)))
    db.commit()
    return {"message": "Payment config berhasil diperbarui"}

@app.post("/admin/payment-config/qris", tags=["Payment Config"])
async def upload_qris_image(
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin),
):
    """Upload gambar QRIS baru. Menggantikan file lama."""
    content = await read_and_validate_image(file)
    filename = f"qris_{uuid.uuid4().hex[:8]}.png"
    dest = os.path.join("uploads", filename)
    with open(dest, "wb") as f:
        f.write(content)
    # Update database record
    row = db.get(models.SiteSetting, "qris_image")
    if row:
        # Hapus file lama jika ada
        if row.value:
            old_filename = row.value.replace("/uploads/", "")
            old_path = os.path.join("uploads", old_filename)
            if os.path.exists(old_path):
                try: os.remove(old_path)
                except Exception: pass
        row.value = f"/uploads/{filename}"
    else:
        db.add(models.SiteSetting(key="qris_image", value=f"/uploads/{filename}"))
    db.commit()
    return {"message": "QRIS berhasil diupload", "url": f"/uploads/{filename}"}

# --- GALLERY & SPECS ---
@app.post("/admin/products/{product_id}/gallery", tags=["Products"])
async def upload_product_gallery(
    product_id: int,
    files: List[UploadFile] = File(...),
    color_hex: Optional[str] = Form(None),
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin),
):
    """Upload multiple gambar ke galeri produk."""
    urls = []
    
    h = None
    if color_hex and color_hex.strip() != '' and color_hex != 'null':
        h = color_hex.strip()
        if not h.startswith("0xFF"):
            h = "0xFF" + h.replace("#", "").upper()
            
    for file in files:
        content = await read_and_validate_image(file)
        filename = f"gallery_{uuid.uuid4().hex[:8]}.png"
        dest = os.path.join("uploads", filename)
        with open(dest, "wb") as f:
            f.write(content)
        
        url = f"/uploads/{filename}"
        db.add(models.ProductImage(product_id=product_id, image_url=url, color_hex=h))
        urls.append(url)
    
    db.commit()
    return {"message": f"{len(urls)} foto ditambahkan ke galeri", "urls": urls}

@app.delete("/admin/products/{product_id}/gallery/{image_id}", tags=["Products"])
def delete_gallery_image(
    product_id: int, 
    image_id: int, 
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin)
):
    """Admin menghapus gambar galeri/warna produk."""
    img = db.query(models.ProductImage).filter(
        models.ProductImage.id == image_id, 
        models.ProductImage.product_id == product_id
    ).first()
    if not img:
        raise HTTPException(status_code=404, detail="Gambar tidak ditemukan")
        
    try:
        path = img.image_url.lstrip("/")
        if os.path.exists(path):
            os.remove(path)
    except Exception as e:
        logger.warning(f"Gagal hapus file fisik gallery: {e}")

    db.delete(img)
    db.commit()
    return {"status": "deleted"}

@app.put("/admin/products/{product_id}/gallery/{image_id}", tags=["Products"])
def update_gallery_image_role(
    product_id: int, 
    image_id: int, 
    payload: schemas.ImageRoleUpdate,
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin)
):
    """Ubah color_hex (peran) dari sebuah image."""
    img = db.query(models.ProductImage).filter(
        models.ProductImage.id == image_id, 
        models.ProductImage.product_id == product_id
    ).first()
    if not img:
        raise HTTPException(status_code=404, detail="Gambar tidak ditemukan")
        
    h = None
    if payload.color_hex and payload.color_hex.strip() != '' and payload.color_hex != 'null':
        h = payload.color_hex.strip()
        if not h.startswith("0xFF"):
            h = "0xFF" + h.replace("#", "").upper()
            
    img.color_hex = h
    db.commit()
    return {"status": "updated", "color_hex": h}

@app.patch("/admin/products/{product_id}/thumbnail/{image_id}", tags=["Products"])
def set_product_thumbnail_from_gallery(
    product_id: int,
    image_id: int,
    db: Session = Depends(database.get_db),
    _: None = Depends(verify_admin)
):
    """Set foto utama produk dari salah satu foto di galeri."""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    img = db.query(models.ProductImage).filter(
        models.ProductImage.id == image_id,
        models.ProductImage.product_id == product_id
    ).first()
    
    if not product or not img:
        raise HTTPException(status_code=404, detail="Produk atau Gambar tidak ditemukan")
    
    product.image = img.image_url
    db.commit()
    return {"status": "thumbnail_updated", "url": img.image_url}

@app.get("/admin/all-products", tags=["Products"])
def get_all_products_admin(db: Session = Depends(database.get_db), _: None = Depends(verify_admin)):
    """Versi detil product untuk kebutuhan admin."""
    return db.query(models.Product).all()
