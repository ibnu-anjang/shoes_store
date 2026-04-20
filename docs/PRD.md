# PRD — Product Requirements Document

| | |
|---|---|
| **Proyek** | Shoes Store E-Commerce |
| **Versi** | 1.0 |
| **Tanggal** | 13 April 2026 |
| **Status** | ✅ Completed |

---

## 1. Overview

Shoes Store adalah aplikasi full-stack e-commerce khusus sepatu dengan sistem pembayaran manual (upload bukti transfer) mirip Shopee/Tokopedia.

**Tujuan utama:**
- Manajemen stok yang akurat (reserved stock system)
- Alur order yang jelas ala marketplace
- Proses verifikasi pembayaran manual oleh admin
- User experience yang baik di mobile (Flutter)

---

## 2. Target User

| User Type | Deskripsi | Jumlah Estimasi |
|---|---|---|
| Customer | Pembeli sepatu (end user) | Banyak |
| Admin | Pemilik toko / tim verifikasi order | 1–3 orang |

---

## 3. Core Features

| Fitur | Status |
|---|---|
| Manajemen Produk dengan variant (SKU & warna) | ✅ |
| Cart & Favorite | ✅ |
| Order dengan full lifecycle | ✅ |
| Upload bukti pembayaran | ✅ |
| Auto-cancel order setelah 24 jam | ✅ |
| Stock management (reserved & available) | ✅ |
| Review produk per item | ✅ |
| Address management | ✅ |
| AI Chatbot lokal (SoleMate via Ollama) | ✅ |
| Admin panel web-based | ✅ |
| Docker Compose + Cloudflare Tunnel | ✅ |

---

## 4. User Flows

### Customer Journey
1. Browse produk → lihat detail + variant (warna & ukuran)
2. Tambah ke Cart → Checkout
3. Pilih alamat → Buat order (status `UNPAID`)
4. Upload bukti pembayaran
5. Pantau status order hingga `COMPLETED`
6. Beri review setelah selesai

### Admin Journey
1. Lihat daftar order masuk
2. Cek bukti pembayaran
3. Approve / Reject order
4. Update status ke `SHIPPED`
5. Kelola produk, stok, dan konfigurasi toko

---

## 5. Order Lifecycle

```
UNPAID ──(upload bukti)──► VERIFYING ──(admin approve)──► PAID
                                                            │
                                                   (admin proses)
                                                            │
                                                            ▼
CANCELLED ◄──(> 24 jam)── UNPAID          SHIPPED ──(konfirmasi)──► COMPLETED
```

**Aturan Bisnis Stok:**
- Saat checkout → stok di-*reserve* (`stock_reserved` bertambah)
- Saat admin approve → stok dikurangi (`stock_available` berkurang)
- Saat order cancel/reject → stok dikembalikan ke `stock_available`

---

## 6. Database Schema

Tabel utama: `products`, `product_skus`, `product_colors`, `users`, `carts`, `cart_items`, `orders`, `order_items`, `payment_confirmations`, `favorites`, `addresses`, `reviews`, `promo_banners`, `transaction_logs`

---

## 7. Tech Stack

| Layer | Teknologi |
|---|---|
| Frontend | Flutter + Provider |
| Backend | FastAPI + SQLAlchemy + MariaDB |
| AI Chatbot | Ollama (`qwen2.5:1.5b`) |
| Infrastructure | Docker Compose + Cloudflare Tunnel |
| File Storage | `backend/uploads/` (static files) |

---

## 8. Non-Functional Requirements

| Aspek | Target |
|---|---|
| Performance | Responsif di mobile, loading cepat |
| Reliability | Transaction safety, auto-cancel reliable |
| Security | File upload validation, rate limiting, Bearer token auth |
| Maintainability | Kode bersih, error handling baik, logging proper |

---

## 9. Roadmap

| Phase | Fokus | Status |
|---|---|---|
| Phase 1 | Fix bug kritis, stock consistency, error handling, security upload | ✅ Selesai |
| Phase 2 | Refactor, logging, optimasi Provider Flutter | ✅ Selesai |
| Phase 3 | UI/UX polish, validasi input, format Rupiah, integrasi AI SoleMate | ✅ Selesai |
