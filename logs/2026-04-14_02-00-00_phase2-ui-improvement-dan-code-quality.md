# Phase 2: UI Improvement (Logo Header) + Code Quality & Maintainability

**Tanggal:** 2026-04-14  
**Branch:** frontendv1-ibenv1  
**Status:** Selesai

---

## Apa yang Dilakukan

Dua kategori pekerjaan: UI improvement dari feedback tester, dan code quality sesuai PRD Phase 2.

## Perubahan

| File | Jenis | Keterangan |
|------|-------|------------|
| `frontend/.../screens/home/homeScreen.dart` | Edit | Tambah logo "Shoes Store" dengan icon `storefront_rounded` di tengah header beranda. Greeting dipindah ke baris bawah logo dengan font sedikit lebih kecil (20→16). |
| `frontend/.../provider/orderProvider.dart` | Edit | `updateStatus` sekarang clear `_error = null` sebelum eksekusi — konsisten dengan pattern provider lain. |
| `frontend/.../provider/addressProvider.dart` | Edit | Tambah `_error` state + getter, clear di `clearAddresses()`, dan set error + `notifyListeners()` di `fetchAddresses` saat gagal. |
| `frontend/.../services/apiService.dart` | Edit | Fix empty catch block di `getCart()` — sekarang `debugPrint` error message (tidak silent fail). |

## Alasan

### UI: Logo di header beranda
- **Feedback tester:** "bagian beranda atas itu kayak terlalu polos banget, di tengahnya bisa ditambahin yang logo itu"
- **Solusi:** Tambah brand logo (icon + teks "Shoes Store") sebagai elemen centered di atas greeting, pakai icon `storefront_rounded` dari Material Icons (tidak butuh asset tambahan).

### Code Quality
- `orderProvider.updateStatus` tidak clear `_error` sebelum eksekusi → old error bisa terlihat di UI walau operasi baru berhasil.
- `addressProvider` tidak punya `_error` state → tidak konsisten dengan provider lain (cart, favorite, order, review).
- Empty catch block di `apiService.getCart()` → error tersembunyi, susah debug.

## Hasil flutter analyze

- **Error:** 0
- **Warning:** 1 (unused import `dart:io` di `description.dart` — pre-existing, bukan dari perubahan ini)
- **Info:** 74 (naming conventions + `withOpacity` deprecated — semua pre-existing)

## Catatan Penting

- `addressProvider.updateAddress()` dan `setDefault()` masih tidak sync ke server (tidak ada PUT endpoint di backend). Ini known limitation — perlu endpoint `PUT /addresses/{id}` untuk fix proper. Ditandai sebagai TODO untuk fase berikutnya.
- Logo beranda tidak pakai asset file — pakai Material Icon agar tidak bergantung bundling asset tambahan.
