from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean, Double
from sqlalchemy.orm import relationship
from app.database import Base
import datetime

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(String(255))
    image = Column(String(255))
    category = Column(String(50))
    rating = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    specification = Column(String(500), nullable=True) # Informasi teknis produk

    # Base price (harga termurah/patokan)
    price = Column(Double, nullable=False, default=0.0) 

    skus = relationship("ProductSku", back_populates="product", cascade="all, delete-orphan")
    colors = relationship("ProductColor", back_populates="product", cascade="all, delete-orphan")
    gallery = relationship("ProductImage", back_populates="product", cascade="all, delete-orphan")

class ProductColor(Base):
    __tablename__ = "product_colors"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    color_hex = Column(String(50), nullable=False) # e.g. "0xFF000000"
    image_url = Column(String(255), nullable=True) # Image for this specific color
    
    product = relationship("Product", back_populates="colors")

class ProductImage(Base):
    __tablename__ = "product_images"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    image_url = Column(String(255), nullable=False)
    color_hex = Column(String(50), nullable=True)
    
    product = relationship("Product", back_populates="gallery")

class ProductSku(Base):
    __tablename__ = "product_skus"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    variant_name = Column(String(50), nullable=False) # misal: "Size 40", "Size 41"
    color_hex = Column(String(50), nullable=True)     # Link to specific color (hex)
    price = Column(Double, nullable=False)
    stock_available = Column(Integer, default=0)
    stock_reserved = Column(Integer, default=0)
    
    product = relationship("Product", back_populates="skus")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    profile_image = Column(String(255))

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))

class Cart(Base):
    __tablename__ = "carts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    items = relationship("CartItem", back_populates="cart", cascade="all, delete-orphan")

class CartItem(Base):
    __tablename__ = "cart_items"
    id = Column(Integer, primary_key=True, index=True)
    cart_id = Column(Integer, ForeignKey("carts.id"))
    sku_id = Column(Integer, ForeignKey("product_skus.id"))
    quantity = Column(Integer, default=1)
    color_hex = Column(String(50), nullable=True) # e.g. "0xFFFFFFFF"
    is_selected_for_checkout = Column(Boolean, default=True)
    
    cart = relationship("Cart", back_populates="items")

class Order(Base):
    __tablename__ = "orders"
    id = Column(String(50), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    subtotal = Column(Double, nullable=True)       # harga produk murni (tanpa kode unik)
    unique_code = Column(Integer)
    total = Column(Double)                          # total_payment = subtotal + unique_code
    status = Column(String(50)) # UNPAID, VERIFYING, PAID, SHIPPED, COMPLETED, CANCELLED
    tanggal = Column(DateTime, default=datetime.datetime.utcnow)
    expired_at = Column(DateTime)
    shipped_at = Column(DateTime, nullable=True)
    payment_method = Column(String(20), nullable=True)   # TF, QRIS, COD
    tracking_number = Column(String(100), nullable=True)
    shipping_address = Column(String(255))
    phone = Column(String(20))
    
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    payment = relationship("PaymentConfirmation", back_populates="order", uselist=False, cascade="all, delete-orphan")
    user = relationship("User")

class OrderItem(Base):
    __tablename__ = "order_items"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(50), ForeignKey("orders.id"))
    sku_id = Column(Integer, ForeignKey("product_skus.id"))
    quantity = Column(Integer)
    price_at_checkout = Column(Double)
    color_hex = Column(String(50), nullable=True)
    
    order = relationship("Order", back_populates="items")
    sku = relationship("ProductSku")

class PaymentConfirmation(Base):
    __tablename__ = "payment_confirmations"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(50), ForeignKey("orders.id"), unique=True)
    proof_image_url = Column(String(255), nullable=False)
    status = Column(String(50), default="PENDING") # PENDING, APPROVED, REJECTED
    uploaded_at = Column(DateTime, default=datetime.datetime.utcnow)

    order = relationship("Order", back_populates="payment")

class Address(Base):
    __tablename__ = "addresses"
    id = Column(String(50), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    label = Column(String(100), nullable=False)
    receiver_name = Column(String(100), nullable=False)
    phone_number = Column(String(50), nullable=False)
    full_address = Column(String(500), nullable=False)
    is_default = Column(Boolean, default=False)
    
class Review(Base):
    __tablename__ = "reviews"
    id = Column(String(50), primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    order_item_id = Column(Integer, ForeignKey("order_items.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    rating = Column(Float, nullable=False)
    comment = Column(String(500))
    image_path = Column(String(255), nullable=True)
    date = Column(DateTime, default=datetime.datetime.utcnow)

class PromoBanner(Base):
    __tablename__ = "promos"
    id = Column(Integer, primary_key=True, index=True)
    image_url = Column(String(255))
    is_active = Column(Boolean, default=True)

class SiteSetting(Base):
    """Key-value store untuk konfigurasi toko (info TF, QRIS image, dll)."""
    __tablename__ = "site_settings"
    key   = Column(String(50), primary_key=True)
    value = Column(String(500), nullable=True)

class TransactionLog(Base):
    __tablename__ = "transaction_logs"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    action = Column(String(255), nullable=False) # e.g., "CHECKOUT_CREATED", "PAYMENT_UPLOADED"
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    details = Column(String(500), nullable=True)

    user = relationship("User")
