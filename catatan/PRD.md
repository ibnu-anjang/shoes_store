PRD — Project Requirements Document
Nama Proyek: Shoes Store E-Commerce
Versi: 1.0 (Focus: Improvement Phase)
Tanggal: 13 April 2026
Status: Draft
1. Overview
Shoes Store adalah aplikasi full-stack e-commerce khusus sepatu yang mengadopsi sistem pembayaran manual (upload bukti transfer) mirip Shopee/Tokopedia.
Tujuan utama aplikasi ini adalah memberikan pengalaman belanja sepatu yang nyaman, transparan, dan reliable, dengan fokus pada:

Manajemen stok yang akurat (reserved stock system)
Alur order yang jelas ala marketplace
Proses verifikasi pembayaran manual oleh admin
User experience yang baik di mobile (Flutter)

Saat ini aplikasi sudah memiliki sebagian besar fitur inti, namun masih perlu tahap improvement yang kuat di bug kritis, stabilitas, keamanan, dan maintainability sebelum masuk ke fase penambahan fitur baru.
2. Target User




















User TypeDeskripsiJumlah EstimasiCustomerPembeli sepatu (end user)BanyakAdminPemilik toko / tim yang verifikasi order1–3 orang
3. Core Features (Existing)
Sudah ada:

Manajemen Produk dengan variant (Product + ProductSku + ProductColor)
Cart & Favorite
Order dengan full lifecycle
Upload bukti pembayaran
Auto-cancel order setelah 24 jam (UNPAID)
Stock management (stock_available & stock_reserved)
Review produk
Address management
Chatbot sederhana
Admin panel sederhana (phpMyAdmin + custom HTML)
Docker Compose + Cloudflare Tunnel

Masih perlu di-improve:

Error handling & transaction safety
Stock consistency
Performance & loading state di Flutter
Security (auth, file upload, rate limiting)
Code quality & maintainability

4. User Flows
Customer Journey

Browse produk → lihat detail + variant (warna & SKU)
Tambah ke Cart → Checkout
Pilih alamat → Buat order (status UNPAID)
Upload bukti pembayaran
Pantau status order (VERIFYING → PAID → SHIPPED → COMPLETED)
Beri review setelah selesai

Admin Journey

Lihat daftar order baru (UNPAID)
Cek bukti pembayaran
Approve / Reject order
Update status ke SHIPPED
Kelola produk & stok

5. Order Lifecycle & Business Rules (Paling Kritis)
Lifecycle:

UNPAID → (customer upload bukti) → VERIFYING
VERIFYING → (admin approve) → PAID
PAID → (admin proses) → SHIPPED
SHIPPED → (customer konfirmasi terima) → COMPLETED
UNPAID > 24 jam → otomatis CANCELLED

Aturan Bisnis Stock:

Saat checkout → stok di-reserve (stock_reserved bertambah)
Saat admin approve → stok benar-benar dikurangi (stock_available berkurang)
Saat order cancel/reject → stok dikembalikan ke stock_available

6. Database Schema (Ringkasan Utama)
Tabel penting:

products
product_skus
product_colors
users
carts & cart_items
orders & order_items
payment_confirmations
favorites
addresses
reviews
promo_banners
transaction_logs

7. Architecture & Tech Stack

Backend: FastAPI + SQLAlchemy + MariaDB
Frontend: Flutter + Provider state management
Infrastructure: Docker Compose (app + db + cloudflare-tunnel + phpMyAdmin)
File Storage: backend/uploads/ (static files)

8. Non-Functional Requirements

Performance: Responsif di mobile, loading cepat
Reliability: Transaction safety, auto-cancel reliable
Security: File upload validation, better authentication, rate limiting
Maintainability: Kode bersih, dokumentasi jelas, error handling baik
Scalability: Siap untuk traffic sedang (bisa di-scale nanti)

9. Technical Constraints & Conventions

Mengikuti CLAUDE.md yang sudah ada
Dart: camelCase untuk file & variabel, PascalCase untuk class
Python: PEP8 + FastAPI best practices
Semua perubahan data harus pakai transaction & proper rollback

10. Improvement Plan / Roadmap (Focus Saat Ini)
Phase 1 – Fix Bug Kritis & Stability (Prioritas Tertinggi)

Fix stock consistency & transaction safety
Upgrade ke async SQLAlchemy
Perbaiki background worker auto-cancel
Improve error handling & logging
Security dasar file upload & auth

Phase 2 – Code Quality & Maintainability

Refactor codebase
Tambah proper logging
Update CLAUDE.md + buat dokumentasi lain
Optimasi Provider di Flutter

Phase 3 – Polish & Small Enhancement

Improve UI/UX & loading states
Tambah input validation lebih ketat
Performance optimization
Persiapan production