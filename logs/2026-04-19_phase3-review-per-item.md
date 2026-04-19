# Phase 3 — Review Per Item untuk Multi-Item Order

**Tanggal:** 2026-04-19

## Masalah yang Diperbaiki
- Checkout keranjang (banyak item) → hanya 1 item yang bisa direview
- ReviewScreen mereview seluruh order, bukan per-item

## Perubahan

### `reviewScreen.dart` (tulis ulang)
- Constructor berubah: `Order order` → `CartItem item` + `String orderId`
- Tampil hanya 1 item (yang dipilih), bukan semua item
- Success view: tombol "Selesai" → `Navigator.pop()` (bukan kembali ke beranda)
  sehingga user bisa langsung review item berikutnya

### `reviewHelper.dart` (baru)
- Fungsi `openReviewPicker(context, order)`:
  - 1 item belum direview → langsung buka ReviewScreen
  - >1 item belum direview → bottom sheet daftar item, tap untuk pilih
- `_ReviewItemPickerSheet`: bottom sheet dengan tile per item

### `orderListScreen.dart`
- Tombol "Beri Review" → pakai `openReviewPicker`

### `orderDetailScreen.dart`
- `_buildReviewButton` → pakai `openReviewPicker`

### `description.dart`
- Tombol edit review: cari CartItem berdasarkan `review.orderItemId`
  (fallback ke product_id match), lalu buka ReviewScreen dengan item tersebut
