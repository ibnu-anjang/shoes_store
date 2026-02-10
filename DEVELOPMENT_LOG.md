# Development Log - Shoes Store Project

Dokumen ini berisi rangkuman seluruh perbaikan, fitur, dan catatan teknis yang dilakukan selama sesi pengerjaan (dimulai dari Jam 14:00 - selesai).

## 🛠️ Perbaikan Utama (Critical Fixes)

### 1. Masalah UI Freeze / Crash Setelah Login
**Masalah:** Aplikasi membeku atau tertutup paksa (CRASH) tepat setelah tombol login ditekan.
**Perbaikan:**
- **Disable Impeller Engine**: Engine rendering baru Flutter (Impeller) memiliki bug pada perangkat Android versi tertentu yang menyebabkan deadlock. Dimatikan melalui `AndroidManifest.xml`.
- **Global Navigation Key**: Navigasi dipindahkan dari `context` lokal ke `GlobalKey<NavigatorState>` di `main.dart`. Ini mencegah error "context not found" atau transisi yang "nyangkut".
- **Keyboard Unfocus**: Menambahkan perintah untuk menutup keyboard secara paksa sebelum berpindah halaman untuk memastikan thread UI bersih.

### 2. Navigasi & Memori
- **CartScreen Stack Overflow**: Memperbaiki tombol "Back" di Keranjang yang sebelumnya memanggil halaman NavBar baru (recursive), sekarang menggunakan `Navigator.pop()`.
- **Hero Animation Optimization**: Memberikan `tag` unik pada setiap `ProductCard` untuk mencegah tabrakan animasi yang bisa membuat aplikasi berat/freeze.

### 3. Backend (FastAPI) - Internal Server Error (500)
**Masalah:** Pendaftaran (Register) gagal dengan error 500 jika username sudah ada.
**Perbaikan:**
- Menambahkan **duplicate check** untuk Username (sebelumnya hanya mengecek email).
- Menambahkan blok **Try-Except** pada proses commit database agar jika ada error mysql, server tidak langsung mati.

---

## ✨ Fitur & Peningkatan Baru
- **Friendly Notifications**: Pesan error login/register sekarang berbahasa Indonesia santai ("Waduh!", "Cuy!", "Username kepake nih!").
- **Logout System**: Menambahkan tombol logout di AppBar yang membersihkan seluruh tumpukan halaman (clear route stack).
- **Isolation Debugging**: Menyiapkan struktur NavBar yang lebih stabil meskipun nantinya akan ditambah aset berat lagi.

---

## 🌐 Rencana Presentasi (Localtunnel)
Untuk mendemonstrasikan aplikasi ini tanpa perlu mengganti IP manual di kode:
1. **Jalankan Backend**: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
2. **Jalankan Localtunnel**: Di terminal baru, gunakan `lt --port 8000 --subdomain shoes-store-api`
3. **Update URL**: Ganti `baseUrl` di `auth_service.dart` dengan URL dari localtunnel (misal: `https://shoes-store-api.loca.lt`).
4. **Keuntungan**: Aplikasi Flutter di HP asli bisa langsung akses server Anda melalui internet tanpa harus dalam 1 WiFi.

---

## 💡 Saran Strategis (Tips Development)

### Untuk Developer Frontend (Teman Anda)
1. **Optimasi Gambar**: JANGAN gunakan gambar mentah berukuran MB. Gunakan ekstensi **.webp** dan kompres ukuran gambar di bawah 200KB jika memungkinkan.
2. **Standard Naming**: Biasakan gunakan `snake_case` untuk nama file (misal: `home_screen.dart`).
3. **Async Safety**: Selalu cek `if (mounted)` sebelum melakukan `setState` atau navigasi setelah sebuah proses `await` (API call).

### Untuk Developer Backend (Anda)
1. **Validasi Server-Side**: Jangan pernah percaya input dari user. Selalu validasi ulang semua data (panjang password, keunikan username) di backend.
2. **Database Rollback**: Jika proses `db.commit()` gagal, pastikan lakukan `db.rollback()` agar sesi database tidak nyangkut.
3. **API Documentation**: Manfaatkan fitur `/docs` (Swagger) FastAPI untuk mengetes endpoint sebelum dihubungkan ke Flutter.

---

## 🚀 Rencana Selanjutnya (PR / Future Tasks)

Berdasarkan instruksi terakhir, berikut adalah fitur yang akan diimplementasikan pada tahap berikutnya:

1. **Persistent Login (Auto-Login)**:
   - Menggunakan `shared_preferences` untuk menyimpan token secara lokal.
   - Saat aplikasi dibuka, sistem akan mengecek keberadaan token; jika ada, user langsung masuk ke `BottomNavBar` tanpa melewati `LoginScreen`.

2. **Offline Support & Stability**:
   - Menghindari crash saat tidak ada koneksi internet.
   - Implementasi caching sederhana (menyimpan data produk terakhir yang berhasil dimuat) agar aplikasi tetap menampilkan informasi saat offline (mode read-only).

3. **Restorasi UI Penuh**:
   - Mengembalikan aset gambar dan font satu per satu setelah stabilitas auto-login terverifikasi.

---
*Dibuat oleh AI Assistant (Antigravity).*
