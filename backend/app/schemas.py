from pydantic import BaseModel
from typing import Optional


class ProductBase(BaseModel):
    name: str
    price: float
    description: Optional[str] = None


class ProductCreate(ProductBase):
    pass  # Digunakan saat input data baru


class ProductResponse(ProductBase):
    id: int

    class Config:
        from_attributes = True  # Agar Pydantic bisa baca model SQLAlchemy


class UserCreate(BaseModel):
    username: str
    email: str
    password: str  # Password asli dari user


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: str

    class Config:
        from_attributes = True
