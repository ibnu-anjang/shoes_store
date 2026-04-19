# Hapus Tombol Simulasi Admin

**Tanggal:** 2026-04-19

## Perubahan
- `orderListScreen.dart`: Hapus blok tombol "Simulasi: Verifikasi Pembayaran" dan "Simulasi: Kirim Paket"
  - Diganti label info: "Menunggu Validasi Pembayaran" (orange) dan "Menunggu Toko Mengirim Barang" (biru)
  - Hapus field `_loadingOrderIds` yang tidak terpakai
  - Bersihkan signature `_buildOrderList` dan `_buildOrderCard` (hapus param `provider` yang tidak dipakai)
- `orderDetailScreen.dart`: Hapus method `_buildSimulateVerifyButton`
  - Diganti method `_buildWaitingInfoCard` (reusable, terima icon/color/text)
  - Status `menungguVerifikasi` → info card orange
  - Status `diproses` → info card biru

## Alasan
APK hampir ready production — tombol simulasi tidak boleh terlihat buyer.
