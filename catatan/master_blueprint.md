# 📘 MASTER BLUEPRINT: SHOES STORE PROJECT 🚀
**"The Developer's Bible" | Status: FINAL REVISION | Deadline: SELASA**

Dokumen ini adalah panduan teknis utama (Blueprint) yang mengunci seluruh standar arsitektur dan fungsionalitas aplikasi Shoes Store. Developer **WAJIB** mematuhi seluruh spesifikasi di bawah ini tanpa kecuali.

---

## 🏛️ 1. SYSTEM ARCHITECTURE (Bahasa Alien)
Struktur teknologi yang digunakan untuk menjamin kestabilan dan skalabilitas aplikasi.
-   **Frontend**: Flutter Framework dengan arsitektur **Provider Pattern** (State Management).
-   **Backend**: FastAPI (Python) dengan **Asynchronous Uvicorn Server**.
-   **Database**: SQLAlchemy ORM (Object Relational Mapper) dengan **SQLite/MySQL** engine.
-   **Infrastruktur**: **Dockerized Environment** (Backend/Dockerfile & docker-compose.yml).
-   **Public Access**: **Cloudflare Tunnel (cloudflared)** terintegrasi dengan **Domain Pribadi User**.
-   **Environment**: Seluruh proses pengembangan dilakukan di laptop ini agar User hanya perlu melakukan *setting & run*.

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

## 🏗️ 6. DEPLOYMENT & INFRASTRUCTURE (MANDATORY)
Developer **DILARANG** memberikan alasan terkait server. Seluruh sistem harus siap lari dengan spesifikasi:
-   **Docker Ready**: Seluruh backend harus bisa dijalankan hanya dengan perintah `docker-compose up --build`. Pastikan semua `environment variables` terkonfigurasi dengan benar.
-   **Cloudflare Tunnel**: Backend harus bisa diakses secara publik melalui **Cloudflare Tunnel** menggunakan **Domain Pribadi** yang sudah disediakan oleh User. 
-   **Zero-Config for User**: Tugas Developer adalah memastikan seluruh proses *build* di laptop ini berhasil (100% success rate). User hanya bertugas memasukkan variabel domain dan menjalankan sistem.

---

## 🏁 7. TUESDAY ZERO-BUG ROADMAP (URGENT)
Prioritas pengerjaan (Urutan tidak boleh dibalik):
1.  **Refactor Names**: Rapikan seluruh nama file agar laporannya "RAPI" (Sketsa 2).
2.  **Sync DB**: Pindahkan data Favorite & Order dari memori HP ke Database asli (SQLAlchemy).
3.  **Activate Chatbot**: Sambungkan UI ke Gemini AI Backend.
4.  **Admin Docs**: Pastikan endpoint CRUD barang berfungsi 100% di Swagger untuk demo presentasi.
5.  **Dockerize Everything**: Pastikan sistem siap dijalankan via domain dan docker tanpa error.

---

## 🌐 8. REMOTE ACCESS & ONLINE MODE (CLOUDFLARE BRIDGE)
Aplikasi **WAJIB** bisa diakses oleh pihak luar (Teman/Dosen) dari lokasi berbeda tanpa hosting berbayar:
1.  **Technology**: Gunakan **Cloudflare Tunnel** yang sudah ada di `docker-compose.yml`.
2.  **Frontend Config**: Alamat API di Flutter sudah disentralisasi di `lib/constant.dart`. 
    -   Untuk Demo Lokal: Gunakan `http://10.0.2.2:8000`.
    -   Untuk Akses Jarak Jauh: Ganti `kBaseUrl` dengan Domain Cloudflare Anda (Format: `https://api.domainanda.com`).
3.  **Mandat Khusus**: Developer wajib memastikan saat `kBaseUrl` diganti ke domain publik, seluruh fitur (Chatbot, Order, Favorite) tetap berjalan lancar (100% Connectivity).

---

## 📚 9. HANDOVER & KNOWLEDGE TRANSFER (MANDATORY)
Developer **WAJIB** memberikan tutorial singkat dan padat kepada User (dalam bahasa non-teknis) mengenai:
1.  **Cloudflare Setup**: Cara mendapatkan **Tunnel Token** dari Cloudflare Dashboard dan cara memasukkannya ke `docker-compose.yml`.
2.  **Domain Mapping**: Cara menyambungkan domain pribadi ke tunnel tersebut agar aplikasi bisa diakses online.
3.  **Run Strategy**: Panduan satu-tombol untuk menjalankan sistem di laptop ini sehingga User bisa mendemokannya kapan saja tanpa bantuan Developer.

---

**Master Blueprint Created By: Antigravity AI | Shoes Store Dev Team.** 🤛🔥
