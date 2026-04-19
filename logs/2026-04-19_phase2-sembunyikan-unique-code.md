# Phase 2 — Sembunyikan Unique Code dari Buyer

**Tanggal:** 2026-04-19

## Perubahan
- `orderDetailScreen.dart`: Hapus tampilan baris "Kode Unik" beserta tooltip-nya dari card harga
  - `uniqueCode` tetap ada di model dan backend (dipakai untuk matching pembayaran internal)
  - Hanya tampilan di UI buyer yang dihapus

## Alasan
APK hampir production-ready. Kode unik adalah mekanisme internal untuk memudahkan admin
mencocokkan transfer masuk — buyer tidak perlu tahu angka ini.
