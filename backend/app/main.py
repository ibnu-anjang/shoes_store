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
