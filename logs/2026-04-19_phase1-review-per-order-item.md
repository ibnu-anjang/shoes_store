# Phase 1 — Fix Review Constraint Per Order Item

**Tanggal:** 2026-04-19

## Masalah yang Diperbaiki
1. Tombol "Beri Review" masih muncul setelah review (isReviewed hanya di memori Flutter, tidak dari backend)
2. Tidak bisa review produk yang sama di pembelian kedua (constraint UNIQUE per product_id+user_id)

## Perubahan Backend

### `models.py`
- Tambah kolom `order_item_id` (FK ke `order_items.id`, nullable) ke tabel `reviews`

### `schemas.py`
- `OrderResponse`: tambah field `reviewed_item_ids: List[int] = []`

### `main.py`
- `_enrich_order_items()`: terima param opsional `user_id` dan `db`, hitung `reviewed_item_ids` dari review yang ada per order
- `GET /orders`: pass `user_id=user.id, db=db` ke `_enrich_order_items`
- `POST /reviews`: 
  - Tambah form field `order_item_id: int`
  - Constraint uniqueness berubah dari `(product_id, user_id)` → `(order_item_id, user_id)`
  - Simpan `order_item_id` ke record review

## Perubahan Flutter

### `cartItem.dart`
- Tambah field `isReviewed: bool = false`
- Field `id` sekarang diisi `order_items.id` saat parsing order

### `orderModel.dart`
- `isReviewed` berubah dari mutable field → getter: `items.every((i) => i.isReviewed)`

### `apiService.dart`
- `getOrders()`: parse `reviewed_item_ids`, set `isReviewed` per CartItem, isi `id` dengan `order_item_id`
- `addReview()`: kirim `order_item_id` ke backend

### `reviewProvider.dart`
- `ReviewItem`: tambah field `orderItemId: int`
- `addReview()`: pass `order_item_id` dalam payload

### `reviewScreen.dart`
- Cari item pertama yang belum direview sebagai target
- Setelah submit review: `loadOrders()` dari backend (bukan hanya update memori lokal)

### `orderProvider.dart`
- Hapus `markAsReviewed()` — state sekarang dari backend via `loadOrders()`

## Catatan Migration DB
Kolom `order_item_id` di tabel `reviews` harus ditambahkan manual atau via migration:
```sql
ALTER TABLE reviews ADD COLUMN order_item_id INT NULL REFERENCES order_items(id);
```
