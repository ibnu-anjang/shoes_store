from pydantic import BaseModel
from typing import Optional, List
import datetime


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
    profile_image: Optional[str] = None

    class Config:
        from_attributes = True

# --- FAVORITE SCHEMAS ---
class FavoriteBase(BaseModel):
    product_id: int

class FavoriteCreate(FavoriteBase):
    pass

class FavoriteResponse(FavoriteBase):
    id: int
    user_id: int
    class Config:
        from_attributes = True

# --- ORDER SCHEMAS ---
class OrderItemResponse(BaseModel):
    product_id: int
    quantity: int
    selected_size: int
    selected_color: str
    price: float
    class Config:
        from_attributes = True


class OrderBase(BaseModel):
    id: Optional[str] = None
    total: float
    status: str


class OrderCreate(OrderBase):
    items: List[OrderItemResponse]

class OrderResponse(OrderBase):
    user_id: int
    tanggal: datetime.datetime
    items: List[OrderItemResponse]
    class Config:
        from_attributes = True

# --- CHAT SCHEMAS ---
class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str
