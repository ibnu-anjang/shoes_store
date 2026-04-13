# 🎓 HANDOVER & TUTORIAL: SHOES STORE PROJECT 🚀

Halo! Panduan ini dibuat khusus untuk kamu agar bisa menjalankan dan mengelola aplikasi **Shoes Store** secara mandiri tanpa bantuan developer lagi.

---

## 🔑 1. Setup API Key Gemini (AI Chatbot)
Agar asisten chatbot kamu jadi pintar, kamu butuh API Key dari Google.
1.  Buka [Google AI Studio](https://aistudio.google.com/app/apikey).
2.  Klik **"Create API key"**.
3.  Salin (Copy) kodenya.
4.  Buka folder `backend/`, buat file baru bernama `.env`.
5.  Tempelkan kode tadi di sana:
    ```env
    GOOGLE_API_KEY=AIzaSy... (isi dengan kode kamu)
    ```
    *Jika .env belum diisi, sistem otomatis akan menggunakan "Simulasi Pintar" agar demo tetap jalan!*

---

## 🌐 2. Setup Cloudflare Tunnel (Online Mode)
Agar teman atau dosen bisa akses aplikasi kamu lewat internet:
1.  Buka Dashboard Cloudflare kamu.
2.  Cari menu **Access -> Tunnels**.
3.  Buat Tunnel baru dan dapatkan **Token**-nya (kode panjang).
4.  Buka file `docker-compose.yml` di folder utama.
5.  Cari bagian `tunnel:` dan ganti token di baris `command` dengan token kamu.
6.  **Public Hostname**: Sambungkan domain kamu (misal: `api.sepatuanda.com`) ke `http://app:8000`.

### 📱 Cara Temanmu Mencoba via HP:
Jika kamu sudah berhasil membuat tunnel di atas:
1. Buka file `frontend/shoes_store/lib/constant.dart`
2. Ubah `kBaseUrl` menjadi URL Cloudflare kamu:
   ```dart
   // Contoh kalau URL kamu adalah https://api.sepatuanda.com
   const kBaseUrl = "https://api.sepatuanda.com"; 
   ```
3.  Jalankan aplikasi (di Emulator, Linux Desktop, atau HP asli) dan bagikan file `.apk`-nya ke temanmu jika diperlukan! Temanmu sekarang akan terhubung ke database dan bot AI di laptopmu melalui internet.

---

## 🛍️ 3. Manajemen Barang (Admin Portal)
Kamu tidak butuh aplikasi khusus untuk tambah/hapus sepatu. Cukup pakai browser:
1.  Jalankan sistem (lihat poin 4).
2.  Buka browser dan ketik: `http://localhost:8000/docs`
3.  Cari bagian **"products"**.
4.  Gunakan tombol **"Try it out"** untuk menambah (`POST`) atau melihat (`GET`) data sepatu.
    *Cara ini jauh lebih rapi dan standar profesional sesuai Master Blueprint.*

---

## ⚡ 4. Cara Menjalankan Sistem (One-Button Run)
Untuk menjalankan semuanya sekaligus (Database + Backend + Admin):
1.  Buka terminal/command prompt di folder project.
2.  Ketik perintah sakti ini:
    ```bash
    docker-compose up --build -d
    ```
3.  Selesai! Semua sistem sekarang berjalan di latar belakang.

---

## 🏁 Final Audit Status:
*   [x] **Refactor Names**: Nama file sudah rapi & standar `camelCase`.
*   [x] **Sync DB**: Favorit & Order sudah tersimpan di Database.
*   [x] **Activate Chatbot**: Hybrid AI (Gemini + Fallback) sudah aktif.
*   [x] **Admin Docs**: Swagger UI siap di `/docs`.
*   [x] **Docker Ready**: Siap dijalankan dengan satu perintah.

**Sistem SIAP untuk presentasi hari Selasa! 🤛🔥**
