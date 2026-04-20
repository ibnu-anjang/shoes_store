# ============================================================
# Shoes Store — Makefile untuk Development & Debugging
# Cara pakai: ketik `make <perintah>` di folder ini
# ============================================================

# Gabungan file compose untuk mode dev
DEV_COMPOSE = docker compose -f docker-compose.yml -f docker-compose.dev.yml

# ── DEV MODE (paling sering dipakai) ────────────────────────

## Jalankan semua service dalam mode development (hot-reload aktif)
dev:
	$(DEV_COMPOSE) up

## Jalankan di background (tidak blokir terminal)
dev-bg:
	$(DEV_COMPOSE) up -d

## Hentikan semua service
stop:
	$(DEV_COMPOSE) down

# ── REBUILD (pakai saat ganti requirements.txt / Dockerfile) ─

## Rebuild image app lalu jalankan dev mode
rebuild:
	$(DEV_COMPOSE) up --build

## Rebuild dari nol (hapus image lama juga)
rebuild-clean:
	$(DEV_COMPOSE) build --no-cache app
	$(DEV_COMPOSE) up

# ── LOGS & MONITORING ────────────────────────────────────────

## Lihat log realtime dari container app (Ctrl+C untuk stop)
logs:
	docker logs -f my_uvicorn_app

## Lihat log app + DB sekaligus
logs-all:
	$(DEV_COMPOSE) logs -f app db

## Lihat 50 baris log terakhir app
logs-tail:
	docker logs --tail=50 my_uvicorn_app

# ── RESTART CEPAT ────────────────────────────────────────────

## Restart hanya container app (tanpa rebuild, tanpa matikan DB)
restart:
	docker restart my_uvicorn_app

## Restart app lalu langsung tampilkan log
restart-log:
	docker restart my_uvicorn_app && docker logs -f my_uvicorn_app

# ── DATABASE ─────────────────────────────────────────────────

## Buka phpMyAdmin di browser
pma:
	xdg-open http://localhost:8080 2>/dev/null || echo "Buka http://localhost:8080 di browser"

## Masuk ke shell MariaDB langsung
db-shell:
	docker exec -it shoes_store_db mariadb -u root db_shoes_store

## Cek status semua container
status:
	docker compose -f docker-compose.yml ps

# ── PRODUCTION MODE ──────────────────────────────────────────

## Jalankan mode production (seperti di server, tanpa hot-reload)
prod:
	docker compose -f docker-compose.yml up

## Jalankan production di background
prod-bg:
	docker compose -f docker-compose.yml up -d

# ── BERSIH-BERSIH ────────────────────────────────────────────

## Hapus semua container (data DB tetap aman di volume)
clean:
	$(DEV_COMPOSE) down --remove-orphans

## Hapus semua + hapus volume DB (HATI-HATI: data hilang!)
clean-all:
	$(DEV_COMPOSE) down --volumes --remove-orphans

# ── BANTUAN ──────────────────────────────────────────────────

## Tampilkan daftar perintah ini
help:
	@echo ""
	@echo "  Shoes Store — Perintah yang tersedia:"
	@echo ""
	@echo "  DEV MODE"
	@echo "    make dev          Jalankan dev mode (hot-reload)"
	@echo "    make dev-bg       Dev mode di background"
	@echo "    make stop         Hentikan semua service"
	@echo ""
	@echo "  REBUILD (pakai jika ganti requirements.txt)"
	@echo "    make rebuild      Rebuild app + jalankan"
	@echo "    make rebuild-clean Rebuild bersih dari nol"
	@echo ""
	@echo "  LOGS"
	@echo "    make logs         Log realtime app"
	@echo "    make logs-all     Log app + DB bersamaan"
	@echo "    make logs-tail    50 baris log terakhir"
	@echo ""
	@echo "  RESTART"
	@echo "    make restart      Restart app (tanpa rebuild)"
	@echo "    make restart-log  Restart + langsung lihat log"
	@echo ""
	@echo "  DATABASE"
	@echo "    make pma          Buka phpMyAdmin"
	@echo "    make db-shell     Masuk shell MariaDB"
	@echo "    make status       Status semua container"
	@echo ""
	@echo "  PRODUCTION"
	@echo "    make prod         Jalankan mode production"
	@echo ""
	@echo "  BERSIH-BERSIH"
	@echo "    make clean        Hapus container (data aman)"
	@echo "    make clean-all    Hapus container + data DB (!)"
	@echo ""

.PHONY: dev dev-bg stop rebuild rebuild-clean logs logs-all logs-tail \
        restart restart-log pma db-shell status prod prod-bg \
        clean clean-all help
