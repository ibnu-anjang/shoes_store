# Shoes Store

A full-stack mobile e-commerce app for footwear, featuring manual payment verification, stock management, and a local AI chatbot — built with Flutter and FastAPI.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.128-009688?logo=fastapi)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)
![MariaDB](https://img.shields.io/badge/MariaDB-10.11-003545?logo=mariadb)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

---

## Features

- Register & Login
- Product browsing with category filter and server-side search
- Multi-variant products: size (SKU) & color
- Cart & Checkout
- Manual payment proof upload
- Full order lifecycle: `UNPAID → VERIFYING → PAID → SHIPPED → COMPLETED`
- Auto-cancel orders after 24 hours without payment
- Product reviews with auto-recalculated ratings
- Favorites & address management
- AI Chatbot "SoleMate" powered by Ollama (local, no API key needed)
- Web-based Admin Panel at `/management`
- Promo banners

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x + Provider |
| Backend | FastAPI + SQLAlchemy (Python 3.11) |
| Database | MariaDB 10.11 |
| AI Chatbot | Ollama (`qwen2.5:1.5b`) — runs locally |
| Infrastructure | Docker Compose |
| Public Access | Cloudflare Tunnel |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Ollama](https://ollama.com/) (for AI Chatbot)
- Flutter SDK 3.x (to build APK)

## Getting Started

### 1. Configure environment

```bash
cd backend
cp .env.example .env
# Edit .env: set ADMIN_SECRET_KEY to your own secret
```

### 2. Setup Ollama (AI Chatbot)

```bash
ollama pull qwen2.5:1.5b
sudo systemctl enable --now ollama
```

### 3. Run the stack

```bash
docker compose up -d
```

| Service | URL |
|---|---|
| Backend API | http://localhost:8000 |
| Admin Panel | http://localhost:8000/management |
| Swagger Docs | http://localhost:8000/docs |
| phpMyAdmin | http://localhost:8080 |

### 4. Seed initial data (optional)

```bash
docker exec my_uvicorn_app python seed_orm.py
```

## Project Structure

```
shoes_store/
├── backend/
│   ├── app/
│   │   ├── main.py            # FastAPI routes
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── schemas.py         # Pydantic schemas
│   │   ├── database.py        # DB connection
│   │   └── ollama_service.py  # AI Chatbot service
│   ├── admin_panel/           # Web-based admin panel
│   ├── uploads/               # User-uploaded files (gitignored)
│   ├── seed_orm.py
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   └── shoes_store/           # Flutter app
│       └── lib/
│           ├── screens/
│           ├── provider/
│           ├── services/
│           ├── models/
│           └── constant.dart
└── docker-compose.yml
```

## Order Lifecycle

```
UNPAID ──(upload proof)──► VERIFYING ──(admin approve)──► PAID
   │                                                        │
(> 24h)                                             (admin ships)
   │                                                        │
   ▼                                                        ▼
CANCELLED                                    SHIPPED ──(confirm)──► COMPLETED
```

**Stock logic:**
- Checkout → stock reserved
- Admin approves → stock permanently deducted
- Cancel / Reject → stock restored

## Cloudflare Tunnel (Public Access)

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) → create a new Tunnel → copy the token
2. Replace the token in `docker-compose.yml` under the `tunnel` service
3. Update `_kCloudflareHost` in `frontend/shoes_store/lib/constant.dart` with your domain
4. Rebuild the APK

## Minimum Requirements

| Component | Minimum |
|---|---|
| RAM | 4 GB (8 GB recommended for Ollama) |
| CPU | Dual-core |
| Storage | 5 GB free |
| OS | Linux / macOS / Windows (WSL2 for Docker) |
