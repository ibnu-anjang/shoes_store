# Shoes Store

Full-stack e-commerce mobile app khusus sepatu dengan sistem pembayaran manual, manajemen stok, dan AI chatbot lokal.

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Mobile Frontend | Flutter 3.x + Provider |
| Backend API | FastAPI + SQLAlchemy (Python 3.11) |
| Database | MariaDB 10.11 |
| AI Chatbot | Ollama (`qwen2.5:1.5b`) — lokal, tanpa API key |
| Infrastructure | Docker Compose |
| Public Access | Cloudflare Tunnel |
| File Storage | Local (`backend/uploads/`) |

---

## Fitur Utama

- Autentikasi (Register & Login)
- Browse produk dengan filter kategori & pencarian server-side
- Produk multi-variant: ukuran (SKU) & warna
- Cart & Checkout
- Upload bukti pembayaran manual
- Order lifecycle penuh: `UNPAID → VERIFYING → PAID → SHIPPED → COMPLETED`
- Auto-cancel order setelah 24 jam tanpa pembayaran
- Review produk per item (dengan auto-recalculate rating)
- Favorit & Manajemen Alamat
- AI Chatbot "SoleMate" berbasis Ollama — bisa jawab pertanyaan stok & produk
- Admin Panel web-based (`/management`)
- Promo Banner

---

## Prasyarat

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Ollama](https://ollama.com/) (untuk AI Chatbot)
- Flutter SDK 3.x (untuk build APK)

---

## Cara Menjalankan

### 1. Setup Environment

```bash
cd backend
cp .env.example .env
# Edit .env: isi ADMIN_SECRET_KEY dengan key rahasia kamu
```

### 2. Setup Ollama (AI Chatbot)

```bash
ollama pull qwen2.5:1.5b
sudo systemctl enable --now ollama
```

### 3. Jalankan Sistem

```bash
# Dari root project
docker compose up -d
```

| Service | URL |
|---|---|
| Backend API | http://localhost:8000 |
| Admin Panel | http://localhost:8000/management |
| API Docs (Swagger) | http://localhost:8000/docs |
| phpMyAdmin | http://localhost:8080 |

### 4. Isi Data Awal (opsional)

```bash
docker exec my_uvicorn_app python seed_orm.py
```

---

## Konfigurasi Cloudflare Tunnel (Akses Publik)

1. Buka [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) → buat Tunnel baru → salin token
2. Ganti token di `docker-compose.yml` bagian service `tunnel`
3. Update `_kCloudflareHost` di `frontend/shoes_store/lib/constant.dart` dengan domain kamu
4. Build ulang APK

---

## Struktur Proyek

```
shoes_store/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI routes
│   │   ├── models.py        # SQLAlchemy models
│   │   ├── schemas.py       # Pydantic schemas
│   │   ├── database.py      # DB connection
│   │   └── ollama_service.py # AI Chatbot service
│   ├── admin_panel/         # Web admin panel
│   ├── uploads/             # File upload storage (gitignored)
│   ├── seed_orm.py          # Seed data
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   └── shoes_store/         # Flutter app
│       └── lib/
│           ├── screens/
│           ├── provider/
│           ├── services/
│           ├── models/
│           └── constant.dart
├── docs/
│   ├── PRD.md
│   └── handover_tutorial.md
└── docker-compose.yml
```

---

## Order Lifecycle

```
UNPAID ──(upload bukti)──► VERIFYING ──(admin approve)──► PAID
   │                                                        │
(> 24 jam)                                          (admin proses)
   │                                                        │
   ▼                                                        ▼
CANCELLED                                    SHIPPED ──(konfirmasi)──► COMPLETED
```

**Logika Stok:**
- Checkout → stok di-*reserve*
- Admin approve → stok dikurangi permanent
- Cancel / Reject → stok dikembalikan

---

## Spesifikasi Minimum (Server/Laptop)

| Komponen | Minimum |
|---|---|
| RAM | 4 GB (8 GB direkomendasikan untuk Ollama) |
| CPU | Dual-core |
| Storage | 5 GB free (Docker images + DB + uploads) |
| OS | Linux / macOS / Windows (dengan WSL2 untuk Docker) |

---

## Dokumentasi Lengkap

Lihat folder `docs/` untuk:
- `PRD.md` — Product Requirements Document
- `handover_tutorial.md` — Panduan operasional & catatan pengembangan selanjutnya
