# 📘 MASTER BLUEPRINT: SHOES STORE PROJECT 🚀
**"The Developer's Bible" | Status: FINAL REVISION | Deadline: SELASA**

Dokumen ini adalah panduan teknis utama (Blueprint) yang mengunci seluruh standar arsitektur dan fungsionalitas aplikasi Shoes Store. Developer **WAJIB** mematuhi seluruh spesifikasi di bawah ini tanpa kecuali.

---

## 🏛️ 1. SYSTEM ARCHITECTURE (Bahasa Alien)
Struktur teknologi yang digunakan untuk menjamin kestabilan dan skalabilitas aplikasi.
-   **Frontend**: Flutter Framework dengan arsitektur **Provider Pattern** (State Management).
-   **Backend**: FastAPI (Python) dengan **Asynchronous Uvicorn Server**.
-   **Database**: SQLAlchemy ORM (Object Relational Mapper) dengan **SQLite/MySQL** engine.
-   **Infrastruktur**: **Dockerized Environment** (Backend/Dockerfile) siap deploy via **Cloudflare Tunnel**.

---

## 📐 2. COMPLIANCE AUDIT (SKETSA HAL. 2)
Daftar pelanggaran standar (Non-Compliance) yang **Wajib** di-refactor (diperbaiki) segera:

### A. Pelanggaran Penamaan File (Blacklist)
Aturan: `camelCase` dan diawali huruf kecil (`homePageScreen.dart`).
-   ❌ `register_screen.dart` ➡️ ✅ `registerScreen.dart`
-   ❌ `login_screen.dart` ➡️ ✅ `loginScreen.dart`
-   *Catatan: Semua file di folder auth, cart, dan chatbot harus disinkronkan.*

### B. Pelanggaran Class & Variabel
-   **Class**: Harus **PascalCase** (Contoh: `HomeScreenButton`).
-   **Variable**: Harus **Snake_Case** (Underscore `_`) khusus untuk variabel privat sesuai instruksi sketsa.

---

## 🧬 3. DATABASE ERD SPECIFICATION (THE MISSING MODELS)
Untuk menghidupkan fitur "Mati" (History & Favorite), Developer **Wajib** menambahkan Model berikut ke `models.py`:

```python
# MODEL PERSISTENSI (Wajib Ada)
class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    total_price = Column(Float)
    items = Column(String)  # Simpan sebagai JSON String
    status = Column(String) # 'Pending', 'Processed', 'Sent', 'Received'

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
```

---

## 🤖 4. AI INTEGRATION STRATEGY (CHATBOT)
Langkah teknis menghidupkan Chatbot menggunakan **Google Gemini API**:

1.  **Backend Integration**:
    -   Install: `pip install google-generativeai`.
    -   Endpoint: `POST /chat`.
    -   Logic: Gunakan API Key di `.env` (Header: `x-api-key`).
2.  **Frontend Integration**:
    -   Ubah `onPressed: sendMessage` di `chatBotScreen.dart` agar melakukan HTTP POST ke `/chat`.
    -   Tampilkan pesan "Bot is typing..." selama request berlangsung.

---

## 🌐 5. ADMIN PORTAL MANAGEMENT (WEB-BASED)
Sesuai sketsa pengerjaan Admin via Web:
-   **Mechanism**: Optimalkan **Swagger UI OpenAPI** (`/docs`).
-   **Rule**: Semua operasional CRUD (Tambah/Hapus Stok Sepatu) harus dilakukan via browser di alamat: `http://localhost:8000/docs`. Developer wajib menyediakan dokumentasi endpoint yang RAPI.

---

## 🏁 6. TUESDAY ZERO-BUG ROADMAP (URGENT)
Prioritas pengerjaan (Urutan tidak boleh dibalik):
1.  **Refactor Names**: Rapikan seluruh nama file agar laporannya "RAPI" (Sketsa 2).
2.  **Sync DB**: Pindahkan data Favorite & Order dari memori HP ke Database asli (SQLAlchemy).
3.  **Activate Chatbot**: Sambungkan UI ke Gemini AI Backend.
4.  **Admin Docs**: Pastikan endpoint CRUD barang berfungsi 100% di Swagger untuk demo presentasi.

---

**Master Blueprint Created By: Antigravity AI | Shoes Store Dev Team.** 🤛🔥
