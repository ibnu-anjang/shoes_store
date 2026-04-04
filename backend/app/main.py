from app import models, database, schemas
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from passlib.context import CryptContext
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware

# Setup pengacak password
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Import dari file lokal kita

# Perintah untuk membuat tabel otomatis di MySQL saat server start
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Shoes Store API")

# --- ENDPOINT PRODUK ---

# Izinkan semua perangkat (HP, Laptop lain) akses API ini
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simpan Sepatu Baru (POST)


@app.post("/products", response_model=schemas.ProductResponse)
def create_product(product: schemas.ProductCreate, db: Session = Depends(database.get_db)):
    new_product = models.Product(
        name=product.name,
        price=product.price,
        description=product.description
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

# Ambil Semua Daftar Sepatu (GET)


@app.get("/products", response_model=List[schemas.ProductResponse])
def get_all_products(db: Session = Depends(database.get_db)):
    return db.query(models.Product).all()

# Cari Sepatu Berdasarkan Nama (Fitur Filter di Buku Catatanmu)


@app.get("/products/search")
def search_products(name: str, db: Session = Depends(database.get_db)):
    results = db.query(models.Product).filter(
        models.Product.name.contains(name)).all()
    return results

# Tes Koneksi


@app.get("/")
def read_root():
    return {"status": "Success", "message": "Backend Shoes Store Active!"}

# Endpoint Login untuk mendapatkan Token


@app.post("/token")
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(database.get_db)
):
    # 1. Cari usernya di database
    user = db.query(models.User).filter(
        models.User.username == form_data.username).first()

    # 2. Cek username & password (bandingkan hash-nya)
    if not user or not pwd_context.verify(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=400, detail="Username atau password salah, Cuy!")

    # 3. Kirim Token (sementara kita kirim teks biasa dulu biar gampang)
    return {
        "access_token": f"token-rahasia-{user.username}",
        "token_type": "bearer"
    }


# Endpoint Login menggunakan JSON
@app.post("/login")
def login_with_json(
    user_data: schemas.UserLogin,
    db: Session = Depends(database.get_db)
):
    # 1. Cari usernya di database
    user = db.query(models.User).filter(
        models.User.username == user_data.username).first()

    # 2. Cek username & password
    if not user or not pwd_context.verify(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=400, detail="Username atau password salah, Cuy!")

    # 3. Kirim Token
    return {
        "access_token": f"token-rahasia-{user.username}",
        "token_type": "bearer",
        "username": user.username,
        "email": user.email
    }

# Register User Baru


@app.post("/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):

    if len(user.password) > 72:
        raise HTTPException(
            status_code=400, detail="Password kepanjangan, maksimal 72 karakter!")

    # 1. Cek apakah email sudah terdaftar
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(
            status_code=400, detail="Email sudah dipakai, cari lain!")
            
    # 2. Cek apakah username sudah terdaftar
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(
            status_code=400, detail="Username sudah ada yang punya, pilih lain!")

    # 3. Acak password
    hashed_pwd = pwd_context.hash(user.password)

    # 4. Simpan dengan pengamanan try-except
    try:
        new_user = models.User(
            username=user.username,
            email=user.email,
            hashed_password=hashed_pwd
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
    except Exception as e:
        db.rollback()
        print(f"DATABASE ERROR: {e}")
        raise HTTPException(
            status_code=500, detail="Gagal menyimpan ke database. Coba lagi nanti.")

# --- ENDPOINT FAVORITE (WISHLIST) ---

@app.post("/favorites", response_model=schemas.FavoriteResponse)
def toggle_favorite(fav: schemas.FavoriteCreate, username: str, db: Session = Depends(database.get_db)):
    # Cari user berdasarkan username (karena token kita sementara pakai username)
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    # Cek apakah sudah ada di favorit
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
def get_user_favorites(username: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    # Join favorit dengan produk
    results = db.query(models.Product).join(
        models.Favorite, models.Product.id == models.Favorite.product_id
    ).filter(models.Favorite.user_id == user.id).all()
    
    return results

# --- ENDPOINT ORDERS (HISTORY) ---

@app.post("/orders", response_model=schemas.OrderResponse)
def create_order(order_data: schemas.OrderCreate, username: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    new_order = models.Order(
        id=order_data.id,
        user_id=user.id,
        total=order_data.total,
        status=order_data.status
    )
    db.add(new_order)
    
    for item in order_data.items:
        db_item = models.OrderItem(
            order_id=order_data.id,
            product_id=item.product_id,
            quantity=item.quantity,
            selected_size=item.selected_size,
            selected_color=item.selected_color,
            price=item.price
        )
        db.add(db_item)
    
    db.commit()
    db.refresh(new_order)
    return new_order

@app.get("/orders", response_model=List[schemas.OrderResponse])
def get_order_history(username: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    return db.query(models.Order).filter(models.Order.user_id == user.id).all()

# --- ENDPOINT CHATBOT (SIMULASI PINTAR) ---

@app.post("/chat", response_model=schemas.ChatResponse)
def chat_with_bot(request: schemas.ChatRequest):
    msg = request.message.lower()
    
    # Logika Bot Sederhana tapi Terlihat Pintar untuk Presentasi
    if "promo" in msg or "diskon" in msg:
        reply = "Tentu! Saat ini ada promo diskon 20% untuk semua koleksi Jordan. Gunakan kode: SHOES20."
    elif "kirim" in msg or "ongkir" in msg:
        reply = "Kami mendukung pengiriman ke seluruh Indonesia via JNE dan SiCepat. Gratis ongkir untuk pembelian di atas $200!"
    elif "stok" in msg or "ready" in msg:
        reply = "Semua produk yang tampil di aplikasi kami saat ini berstatus Ready Stock, Kak."
    elif "halo" in msg or "hi" in msg or "p" in msg:
        reply = "Halo! Saya Sneakerhead Assistant. Ada yang bisa saya bantu seputar produk sepatu kami?"
    else:
        reply = "Pertanyaan yang bagus! Untuk info lebih detail, Anda bisa menghubungi tim support kami atau cek deskripsi di tiap produk ya."
    
    return {"reply": reply}
