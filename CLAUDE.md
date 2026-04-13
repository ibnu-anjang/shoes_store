# CLAUDE.md

Panduan utama untuk Claude Code dalam project ini.

## Project Overview
Full-stack e-commerce shoes store:
- **Backend**: FastAPI + SQLAlchemy + MariaDB (Docker)
- **Frontend**: Flutter (Dart) dengan Provider pattern
- **Infrastructure**: Docker Compose (MariaDB + App + Cloudflare Tunnel + phpMyAdmin)

**Tujuan utama**: Membuat aplikasi stabil, performa baik, dan mudah di-maintain.

## Core Principles & Workflow
1. **Plan First** — Selalu buat rencana lengkap sebelum coding besar.
2. **Use Tools** — Gunakan MCP dan Skills yang relevan.
3. **Verify** — Test atau cek hasil sebelum selesai.
4. **Log & Memory** — Selalu buat Activity Log dan update memory jika perlu.

**Urutan kerja wajib**:
Plan → Analyze (pakai Filesystem/Context7) → Execute → Verify → Activity Log → Update Memory jika ada keputusan penting.

## Skills & Memory
- **Skills**: Simpan di folder `.claude/skills/<nama-skill>/SKILL.md`
  Rekomendasi skill untuk project ini:
  - `fix-product-image` → Bug gambar tidak muncul (Home, Cart, Favorite)
  - `correct-order-total` → Perbaikan logika total harga & stock
  - `flutter-image-handling` → Best practices CachedNetworkImage + FastAPI static files
  - `debug-pricing-logic` → Debugging harga, diskon, dan stock reservation

- **Memory**: 
  - File ini (`CLAUDE.md`) adalah memory dasar project.
  - Update bagian "Decisions & Lessons Learned" jika ada perubahan arsitektur atau bug penting yang sudah diselesaikan.
  - Claude otomatis membaca folder `.claude/` setiap sesi.

## MCP Servers (Recommended)

| MCP Server       | Kegunaan Utama                                      | Install Command |
|------------------|-----------------------------------------------------|-----------------|
| **context7**     | Dokumentasi terbaru Flutter, FastAPI, SQLAlchemy    | `claude mcp add context7 -- npx -y @upstash/context7-mcp` |
| **filesystem**   | Baca, edit, search file di project                  | `claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem` |
| **github**       | Commit, branch, PR, issue management                | `claude mcp add github -- npx -y @modelcontextprotocol/server-github` |
| **playwright**   | Test UI (cek gambar muncul/tidak di layar)          | `claude mcp add playwright -- npx @playwright/mcp@latest` |
| **brave-search** | Cari solusi bug terbaru                             | `claude mcp add brave-search -- npx -y @modelcontextprotocol/server-brave-search` |

**Aturan MCP**:
- Selalu pakai **context7** sebelum menulis kode yang melibatkan library/API.
- Gunakan **filesystem** + **playwright** saat debug bug visual (gambar, layout, harga).

## Activity Log (WAJIB)
Setelah **setiap task** selesai (kecil atau besar), buat file log di folder `logs/` dengan format:
`YYYY-MM-DD_HH-MM-SS_<deskripsi-singkat>.md`

Gunakan struktur log yang jelas (bahasa Indonesia).

## Coding Standards
- **Dart**: File `camelCase`, Class `PascalCase`, Private `_camelCase`
- **Flutter**: Selalu gunakan Provider pattern, optimistic update di Cart/Favorite/Review
- **FastAPI**: Gunakan logging module, validasi image ketat, jangan pakai print()
- **Image Handling**: Upload ke `backend/uploads/`, serve via `/uploads/`

## Key Decisions & Lessons Learned
- Order lifecycle mengikuti model Shopee (UNPAID → VERIFYING → PAID → ...)
- Stock reserved saat checkout, deducted saat payment approved
- Auth sederhana: token = "token-rahasia-{username}"
- kBaseUrl di constant.dart harus menyesuaikan platform (localhost / 10.0.2.2 / Cloudflare)

---

**Instruksi Ketat untuk Claude**:
- Prioritaskan akurasi dan stabilitas.
- Jangan pernah hardcode URL production di kode Flutter.
- Selalu gunakan Context7 untuk cek API/library terbaru.
- Buat Activity Log tanpa terkecuali.
- Jika ragu, tanyakan dulu sebelum coding.
