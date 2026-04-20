# Activity Log — Upgrade Order Flow & Backend Logic
**Tanggal:** 2026-04-20 01:37

## Tujuan
Upgrade alur order menjadi profesional sesuai standar e-commerce: status baru, rejection flow, auto-cancel/complete, tombol batal, dan stock management yang benar.

## Perubahan Backend

### models.py
- Tambah kolom `shipped_at` (DateTime nullable) di tabel `orders`.

### schemas.py
- Tambah field `shipped_at: Optional[datetime]` di `OrderResponse`.

### main.py
1. **Migration**: Tambah migrasi otomatis untuk kolom `shipped_at`.
2. **Helper `_return_stock_for_order()`**: Fungsi baru untuk mengembalikan stok order (stock_available += qty, stock_reserved -= qty).
3. **`auto_cancel_orders_worker` diperbarui**:
   - Auto-cancel mencakup **UNPAID** dan **VERIFYING** yang melewati `expired_at`.
   - Tambah **auto-complete SHIPPED** → DELIVERED jika `shipped_at + 24h` sudah lewat.
4. **`admin_update_order_status` diperbarui**:
   - `REJECTED`: Sekarang set order kembali ke **UNPAID** (bukan CANCELLED), hapus `PaymentConfirmation` agar user bisa re-upload.
   - `SHIPPED`: Set `shipped_at = now()`, kurangi `stock_reserved`.
5. **Endpoint baru `POST /orders/{order_id}/cancel`**: User bisa batalkan pesanan sendiri jika status masih UNPAID atau VERIFYING. Stock dikembalikan otomatis.
6. **`_enrich_order_items`**: Tambah field `subtotal` dan `shipped_at` di response dict.

## Perubahan Flutter

### orderModel.dart
- Tambah `OrderStatus.unpaid` (UNPAID) — dibedakan dari `menungguVerifikasi` (VERIFYING).
- Update `statusText` dan `statusEmoji` untuk semua status.

### apiService.dart
- Fix `_parseOrderFromJson`: UNPAID → `unpaid`, VERIFYING → `menungguVerifikasi`.
- Perbaiki `uploadPayment`: tambah auth header yang hilang.
- Tambah method `cancelOrder(String orderId)`.

### orderProvider.dart
- Tambah `cancelOrder(String orderId)` method.
- Fix `updateStatus` switch: tambah case `OrderStatus.unpaid`.

### orderListScreen.dart
- Tab "Menunggu" filter kedua status: `unpaid` dan `menungguVerifikasi`.
- Tambah banner `unpaid` (amber) dan `menungguVerifikasi` (orange) terpisah di order card.
- Tambah `unpaid` ke status chip.

### orderDetailScreen.dart
- Instruksi pembayaran tampil untuk `unpaid` DAN `menungguVerifikasi`.
- Upload section hanya untuk `unpaid` (bukan berdasarkan `hasPaymentProof`).
- Tambah info card untuk status `unpaid`.
- Tambah **tombol "Batalkan Pesanan"** (hanya untuk `unpaid` dan `menungguVerifikasi`).
- Update timeline untuk membedakan `unpaid` dan `menungguVerifikasi`.

## Status
Semua perubahan selesai. Flutter analyze: 0 error (68 info pre-existing).
