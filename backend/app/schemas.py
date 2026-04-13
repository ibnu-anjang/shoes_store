from pydantic import BaseModel, field_validator, EmailStr
from typing import Optional, List
import datetime
import re

# --- SKU SCHEMAS ---
class ProductSkuBase(BaseModel):
    variant_name: str
    price: float
    stock_available: int
    stock_reserved: int

class ProductSkuCreate(ProductSkuBase):
    pass

class ProductSkuResponse(ProductSkuBase):
    id: int
    product_id: int
    class Config:
        from_attributes = True

class ProductColorBase(BaseModel):
    color_hex: str

class ProductColorCreate(ProductColorBase):
    pass

class ProductColorResponse(ProductColorBase):
    id: int
    product_id: int
    class Config:
        from_attributes = True

# --- PRODUCT SCHEMAS ---
class ProductBase(BaseModel):
    name: str
    price: float
    description: Optional[str] = None
    image: Optional[str] = None
    category: Optional[str] = None
    rating: float = 0.0
    is_active: bool = True

class ProductCreate(ProductBase):
    skus: List[ProductSkuCreate] = []
    colors: List[ProductColorCreate] = []

class ProductResponse(ProductBase):
    id: int
    skus: List[ProductSkuResponse] = []
    colors: List[ProductColorResponse] = []
    class Config:
        from_attributes = True


# --- USER SCHEMAS ---
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

    @field_validator('username')
    @classmethod
    def username_valid(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 3:
            raise ValueError('Username minimal 3 karakter')
        if len(v) > 20:
            raise ValueError('Username maksimal 20 karakter')
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username hanya boleh huruf, angka, dan underscore')
        return v

    @field_validator('password')
    @classmethod
    def password_valid(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError('Password minimal 6 karakter')
        return v

    @field_validator('email')
    @classmethod
    def email_strip(cls, v: str) -> str:
        return v.strip().lower()


class UserLogin(BaseModel):
    username: str
    password: str

    @field_validator('username')
    @classmethod
    def username_strip(cls, v: str) -> str:
        return v.strip()

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    profile_image: Optional[str] = None
    class Config:
        from_attributes = True

class UserProfileUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    profile_image: Optional[str] = None

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

# --- CART SCHEMAS ---
class CartItemAdd(BaseModel):
    sku_id: int
    quantity: int = 1

class CartItemResponse(BaseModel):
    id: int
    cart_id: int
    sku_id: int
    quantity: int
    is_selected_for_checkout: bool
    class Config:
        from_attributes = True

class CartResponse(BaseModel):
    id: int
    user_id: int
    items: List[CartItemResponse] = []
    class Config:
        from_attributes = True

# --- PAYMENT CONFIRMATION SCHEMAS ---
# Didefinisikan SEBELUM OrderResponse karena OrderResponse mereferensikannya
class PaymentConfirmationCreate(BaseModel):
    order_id: str
    proof_image_url: str

class PaymentConfirmationResponse(BaseModel):
    id: int
    order_id: str
    proof_image_url: str
    status: str
    uploaded_at: datetime.datetime
    class Config:
        from_attributes = True

# --- ORDER SCHEMAS ---
class OrderItemResponse(BaseModel):
    id: int
    product_id: Optional[int] = None  # Optional: SKU mungkin tidak punya produk aktif
    sku_id: int
    quantity: int
    price_at_checkout: float
    product_name: Optional[str] = None
    product_image: Optional[str] = None
    variant_name: Optional[str] = None
    class Config:
        from_attributes = True

class OrderBase(BaseModel):
    total: float
    status: str

class OrderStatusUpdate(BaseModel):
    status: str

class CheckoutItem(BaseModel):
    sku_id: int
    quantity: int

class OrderCreate(BaseModel):
    address: str
    phone: str
    items: List[CheckoutItem]

class OrderResponse(OrderBase):
    id: str  # id berupa string (unik kode order dari frontend/backend)
    user_id: int
    unique_code: int
    tanggal: datetime.datetime
    expired_at: datetime.datetime
    shipping_address: Optional[str] = None
    phone: Optional[str] = None
    items: List[OrderItemResponse] = []
    payment: Optional[PaymentConfirmationResponse] = None
    class Config:
        from_attributes = True

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    price: Optional[float] = None
    description: Optional[str] = None
    category: Optional[str] = None

# --- CHAT SCHEMAS ---
class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str

# --- ADDRESS SCHEMAS ---
class AddressBase(BaseModel):
    label: str
    receiver_name: str
    phone_number: str
    full_address: str
    is_default: bool = False

class AddressCreate(AddressBase):
    id: str

class AddressResponse(AddressBase):
    id: str
    user_id: int
    class Config:
        from_attributes = True

# --- REVIEW SCHEMAS ---
class ReviewBase(BaseModel):
    rating: float
    comment: Optional[str] = None
    image_path: Optional[str] = None

class ReviewCreate(ReviewBase):
    id: str
    product_id: int

class ReviewResponse(ReviewBase):
    id: str
    product_id: int
    user_id: int
    username: Optional[str] = None
    date: datetime.datetime
    class Config:
        from_attributes = True

# --- TRANSACTION LOG SCHEMAS ---
class TransactionLogCreate(BaseModel):
    action: str
    details: Optional[str] = None

class TransactionLogResponse(TransactionLogCreate):
    id: int
    user_id: int
    timestamp: datetime.datetime
    class Config:
        from_attributes = True

# --- PROMO BANNER SCHEMAS ---
class PromoResponse(BaseModel):
    id: int
    image_url: str
    is_active: bool
    class Config:
        from_attributes = True
