# Activity Log — Refactor Order & Payment System (Multi-Method)
**Tanggal:** 2026-04-20 02:15

## Tujuan
Implementasi alur pembayaran multi-metode profesional (TF, QRIS, COD) dengan workflow kondisional, tracking number, dan tab "Menunggu Validasi" di Pesanan Saya.

## Perubahan Backend

### models.py
- Tambah kolom `payment_method VARCHAR(20)` (TF/QRIS/COD) ke tabel `orders`
- Tambah kolom `tracking_number VARCHAR(100)` ke tabel `orders`

### schemas.py
- `OrderCreate`: tambah `payment_method: str = 'TF'`
- `OrderStatusUpdate`: tambah `tracking_number: Optional[str] = None`
- `OrderResponse`: tambah `payment_method`, `tracking_number`

### main.py
1. **Migration otomatis** untuk `payment_method` dan `tracking_number`
2. **`_enrich_order_items`**: sertakan `payment_method` dan `tracking_number`
3. **`checkout_cart`**: 
   - Terima `payment_method` dari payload
   - COD → `status=PAID`, `unique_code=0`, `total=subtotal` (tidak ada kode unik)
   - TF/QRIS → `status=UNPAID`, generate `unique_code`, `total = subtotal + unique_code`
4. **`upload_payment_proof`**: 
   - Tambah autentikasi user (bug fix — sebelumnya tidak ada auth!)
   - Tolak jika `payment_method == COD`
   - Validasi `order.user_id == user.id`
5. **`admin_update_order_status`**: 
   - Saat SHIPPED: simpan `tracking_number` dari payload
   - Guard: hanya proses SHIPPED jika status saat ini adalah PAID

## Perubahan Admin Panel

- Badge metode bayar (COD=hijau, TF=biru, QRIS=ungu) di setiap baris order
- Field "Metode Bayar" dan "No. Resi" di expandable detail panel
- Tombol "📦 Kirim" → memanggil `doShip()` bukan `doUpdateStatus()`
- Fungsi baru `doShip(orderId)`: prompt nomor resi, POST ke backend dengan tracking_number
- Label tombol diperbarui: "PAID" → "Setujui", "Kirim barang" dengan resi

## Perubahan Flutter

### apiService.dart
- `_parseOrderFromJson`: parse `payment_method` dan `tracking_number` (→ `resi`)
- `checkoutRemote()`: tambah param `paymentMethod`, kirim ke backend
- `uploadPayment()`: sudah memiliki auth header dari sesi sebelumnya ✓

### orderProvider.dart
- `checkout()`: tambah param `paymentMethod`, forward ke `ApiService.checkoutRemote()`

### checkoutScreen.dart
- `_handleCheckout()`: map `_selectedMethod` → kode backend (`Bank Transfer`→`TF`, `QRIS`→`QRIS`, `COD`→`COD`)
- Pass `paymentMethod` ke `orderProvider.checkout()`

### orderListScreen.dart
- **5 tab → 6 tab**: Semua | Menunggu Bayar | Validasi | Diproses | Dikirim | Selesai
- "Menunggu Bayar" = filter `unpaid` saja
- "Validasi" = filter `menungguVerifikasi` saja (sebelumnya digabung)

### orderDetailScreen.dart
- Sudah benar: COD tidak tampilkan instruksi bayar (guard `paymentMethod != 'COD'`)
- COD mulai dari status PAID → upload section tidak pernah muncul ✓
- Tracking number sudah dihandle via field `resi` → `_buildResiCard()` ✓

## Status
Semua perubahan selesai. Flutter analyze: 0 error (68 info pre-existing).
