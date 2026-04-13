# Phase 3: Polish & Small Enhancement

**Tanggal:** 2026-04-14  
**Branch:** frontendv1-ibenv1  
**Status:** Selesai

---

## Apa yang Dilakukan

Empat improvement dari PRD Phase 3: validasi input ketat, loading states, dan format harga.

## Perubahan

| File | Jenis | Keterangan |
|------|-------|------------|
| `frontend/.../screens/cart/checkoutScreen.dart` | Edit | Tambah validasi nomor WA: cek awalan 08/628, panjang 10–15 digit. Error ditampilkan via SnackBar sebelum lanjut ke dialog konfirmasi. |
| `frontend/.../screens/cart/cartScreen.dart` | Edit | Tombol +/- di-disable saat `provider.isLoading = true`. Quantity number diganti `CircularProgressIndicator` kecil saat loading. |
| `frontend/.../screens/order/orderListScreen.dart` | Edit | Convert `StatelessWidget` → `StatefulWidget`. Tombol simulasi pakai `_loadingOrderIds` Set per order ID — loading indicator muncul saat menunggu API, tombol di-disable. |
| `frontend/.../lib/constant.dart` | Edit | Tambah helper `formatRupiah(num)` — format angka dengan pemisah ribuan (contoh: 150000 → "Rp 150.000"). Tidak butuh package `intl`. |
| `frontend/.../screens/home/widget/productCart.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/favorite/favoriteScreen.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/detail/widget/itemDetails.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/cart/cartScreen.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/cart/checkoutScreen.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/order/orderListScreen.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |
| `frontend/.../screens/order/orderDetailScreen.dart` | Edit | Ganti `toStringAsFixed(0)` → `formatRupiah()` |

## Alasan

### Validasi nomor WA
Sebelumnya hanya cek `isNotEmpty`. Bisa diisi "abc" atau nomor 2 digit dan lolos validasi. Sekarang dicek format 08xxx / 628xxx dan panjang 10–15 digit.

### Loading state cart +/-
Saat tombol + atau - ditekan, ada network call ke server. Sebelumnya tidak ada feedback visual — user bisa tekan berkali-kali dan menyebabkan race condition. Sekarang tombol dan angka qty di-disable selama `provider.isLoading`.

### Loading state tombol simulasi
Sebelumnya tombol simulasi di orderListScreen tidak punya loading feedback. Convert ke StatefulWidget dengan `_loadingOrderIds` Set agar loading state per order (bukan global) — tidak memblok order lain.

### Format harga
`Rp 150000` → `Rp 150.000`. Lebih mudah dibaca. Helper `formatRupiah()` di `constant.dart` dipakai di semua 7 screen yang menampilkan harga. Tidak pakai package `intl` agar tidak tambah dependency.

## Hasil flutter analyze

- **Error:** 0
- **Warning:** 1 (unused import `dart:io` di `description.dart` — pre-existing)
- **Info:** ~74 (naming conventions + `withOpacity` deprecated — semua pre-existing)
