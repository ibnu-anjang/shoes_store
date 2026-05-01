# Handover & Tutorial: Shoes Store Project

Panduan ini untuk menjalankan dan mengelola aplikasi Shoes Store secara mandiri.

---

## 1. Prasyarat

Pastikan sudah terinstall di laptop:
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Ollama](https://ollama.com/) — untuk AI Chatbot lokal
- Flutter SDK (untuk build APK)

---

## 2. Setup Pertama Kali

### Konfigurasi Environment
1. Masuk ke folder `backend/`
2. Salin file contoh: `cp .env.example .env`
3. Edit `.env` dan isi nilai yang sesuai:
   ```env
   ADMIN_SECRET_KEY=isi-dengan-key-rahasia-kamu
   OLLAMA_MODEL=qwen2.5:1.5b
   ```

### Setup Ollama (AI Chatbot)
```bash
# Install model AI (lakukan sekali)
ollama pull qwen2.5:1.5b

# Pastikan service Ollama berjalan
sudo systemctl enable --now ollama
```

---

## 3. Menjalankan Sistem

```bash
# Dari folder root project
docker compose up -d
```

Sistem yang akan berjalan:
- **Backend API** → `http://localhost:8000`
- **Admin Panel** → `http://localhost:8000/management`
- **phpMyAdmin** → `http://localhost:8082`

### Isi Data Awal (opsional)
```bash
docker exec my_uvicorn_app python seed_orm.py
```

---

## 4. Setup Cloudflare Tunnel (Akses Online)

Agar bisa diakses dari luar jaringan lokal:
1. Buka [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Buat Tunnel baru → salin Token-nya
3. Buka `docker-compose.yml`, ganti token di bagian `cloudflare-tunnel`
4. Update `_kCloudflareHost` di `frontend/shoes_store/lib/constant.dart` dengan domain kamu
5. Build ulang APK dan distribute

---

## 5. Admin Panel

Akses di `http://localhost:8000/management` (atau via domain Cloudflare).

Fitur yang tersedia:
- Kelola produk, SKU, warna, dan gambar galeri
- Pantau dan update status order
- Kelola user dan konfigurasi pembayaran
- Upload banner promo

---

## 6. Manajemen Database

Akses phpMyAdmin di `http://localhost:8082` untuk query langsung ke database jika diperlukan.

---

## Status Fitur

| Fitur | Status |
|---|---|
| Autentikasi (Login & Register) | ✅ |
| Browse & Detail Produk | ✅ |
| Cart & Checkout | ✅ |
| Upload Bukti Pembayaran | ✅ |
| Order Lifecycle lengkap | ✅ |
| Review per item | ✅ |
| Favorit | ✅ |
| Manajemen Alamat | ✅ |
| AI Chatbot (SoleMate via Ollama) | ✅ |
| Admin Panel web-based | ✅ |
| Auto-cancel order 24 jam | ✅ |
| Cloudflare Tunnel (akses publik) | ✅ |
| Server-side search & pagination | ✅ |
| Auto-rating recalculation dari review | ✅ |

---

## Catatan Pengembangan Selanjutnya

Fitur-fitur berikut **belum diimplementasikan** dan bisa jadi prioritas next version:

| # | Fitur | Urgensi | Catatan |
|---|---|---|---|
| 1 | **Auth JWT** (ganti token sederhana) | Tinggi | Token saat ini = `"token-rahasia-{username}"` — tidak aman untuk production. Ganti ke JWT dengan expiry & refresh token. |
| 2 | **Push Notification** | Sedang | Untuk notif status order (PAID, SHIPPED, dll). Butuh FCM/OneSignal + device token management. |
| 3 | **Payment Gateway** (Midtrans/Xendit) | Sedang | Saat ini manual upload bukti transfer. Integrasi payment gateway akan otomasi verifikasi. |
| 4 | **Resi & Tracking Link** | Rendah | Admin input nomor resi, customer bisa klik link tracking langsung dari app. |
| 5 | **SoleMate Chatbot — Stateless per sesi** | Rendah | Saat ini chatbot tidak ingat percakapan sebelumnya (stateless by design). Bisa tambah session history jika UX perlu ditingkatkan. |
| 6 | **Pindah ke cloud storage** (S3/R2) | Rendah | Upload gambar saat ini ke `backend/uploads/` lokal. Untuk production skala besar, pindah ke object storage. |
