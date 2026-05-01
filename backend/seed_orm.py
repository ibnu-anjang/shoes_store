import sys
import os

# Menambahkan direktori saat ini ke path agar bisa import app
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app import models

def seed():
    db = SessionLocal()
    # 1. Tambah Produk 1
    p1 = models.Product(
        name="Jordan 1 Retro High",
        price=190.0,
        description="The iconic Jordan 1 in high-top fashion. Premium leather and timeless style.",
        image="https://images.nike.com/is/image/DotCom/CT8527_100_A_PREM?wid=1000",
        category="Sneakers",
        rating=4.8
    )
    db.add(p1)
    db.commit()
    db.refresh(p1)

    s1_1 = models.ProductSku(product_id=p1.id, variant_name="Size 40", price=190.0, stock_available=10)
    s1_2 = models.ProductSku(product_id=p1.id, variant_name="Size 41", price=190.0, stock_available=5)
    s1_3 = models.ProductSku(product_id=p1.id, variant_name="Size 42", price=195.0, stock_available=15)
    db.add_all([s1_1, s1_2, s1_3])

    # 2. Tambah Produk 2
    p2 = models.Product(
        name="Nike Air Max 270",
        price=150.0,
        description="Life is better with Air. The Air Max 270 delivers ultimate comfort.",
        image="https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/awjog9il347mc6f8ba9f/air-max-270-shoe-nnTr9G.png",
        category="Running",
        rating=4.6
    )
    db.add(p2)
    db.commit()
    db.refresh(p2)

    s2_1 = models.ProductSku(product_id=p2.id, variant_name="Size 39", price=150.0, stock_available=20)
    s2_2 = models.ProductSku(product_id=p2.id, variant_name="Size 40", price=150.0, stock_available=10)
    db.add_all([s2_1, s2_2])

    # 3. Tambah Produk 3
    p3 = models.Product(
        name="Adidas Ultraboost Light",
        price=180.0,
        description="Experience epic energy with the new Ultraboost Light, our lightest ever.",
        image="https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/7926639686004b31a31aaf53009589d9_9366/Ultraboost_Light_Shoes_White_HQ6351_01_standard.jpg",
        category="Running",
        rating=4.9
    )
    db.add(p3)
    db.commit()
    db.refresh(p3)

    s3_1 = models.ProductSku(product_id=p3.id, variant_name="Size 41", price=180.0, stock_available=8)
    s3_2 = models.ProductSku(product_id=p3.id, variant_name="Size 42", price=180.0, stock_available=4)
    db.add_all([s3_1, s3_2])

    db.commit()
    db.close()
    print("Database Seeded Successfully using ORM!")

if __name__ == "__main__":
    seed()
