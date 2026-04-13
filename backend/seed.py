import requests

BASE_URL = "http://localhost:8000"

def seed():
    # 1. Tambah Produk 1
    p1 = {
        "name": "Jordan 1 Retro High",
        "price": 190.0,
        "description": "The iconic Jordan 1 in high-top fashion. Premium leather and timeless style.",
        "image": "https://images.nike.com/is/image/DotCom/CT8527_100_A_PREM?wid=1000",
        "category": "Sneakers",
        "rating": 4.8,
        "skus": [
            {"variant_name": "Size 40", "price": 190.0, "stock_available": 10, "stock_reserved": 0},
            {"variant_name": "Size 41", "price": 190.0, "stock_available": 5, "stock_reserved": 0},
            {"variant_name": "Size 42", "price": 195.0, "stock_available": 15, "stock_reserved": 0}
        ]
    }
    requests.post(f"{BASE_URL}/products", json=p1)

    # 2. Tambah Produk 2
    p2 = {
        "name": "Nike Air Max 270",
        "price": 150.0,
        "description": "Life is better with Air. The Air Max 270 delivers ultimate comfort.",
        "image": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/awjog9il347mc6f8ba9f/air-max-270-shoe-nnTr9G.png",
        "category": "Running",
        "rating": 4.6,
        "skus": [
            {"variant_name": "Size 39", "price": 150.0, "stock_available": 20, "stock_reserved": 0},
            {"variant_name": "Size 40", "price": 150.0, "stock_available": 10, "stock_reserved": 0}
        ]
    }
    requests.post(f"{BASE_URL}/products", json=p2)

    # 3. Tambah Produk 3
    p3 = {
        "name": "Adidas Ultraboost Light",
        "price": 180.0,
        "description": "Experience epic energy with the new Ultraboost Light, our lightest ever.",
        "image": "https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/7926639686004b31a31aaf53009589d9_9366/Ultraboost_Light_Shoes_White_HQ6351_01_standard.jpg",
        "category": "Running",
        "rating": 4.9,
        "skus": [
            {"variant_name": "Size 41", "price": 180.0, "stock_available": 8, "stock_reserved": 0},
            {"variant_name": "Size 42", "price": 180.0, "stock_available": 4, "stock_reserved": 0}
        ]
    }
    requests.post(f"{BASE_URL}/products", json=p3)

    print("Seeding Complete!")

if __name__ == "__main__":
    seed()
