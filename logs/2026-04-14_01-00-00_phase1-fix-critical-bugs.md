# Phase 1: Fix Critical Bugs (Gambar, Total Harga, Crash Terima Pesanan)

**Tanggal:** 2026-04-14  
**Branch:** frontendv1-ibenv1  
**Status:** Selesai

---

## Apa yang Dilakukan

Memperbaiki 3 bug kritis yang ditemukan oleh bug tester dari folder `perbaikan/`.

## Perubahan

| File | Jenis | Keterangan |
|------|-------|------------|
| `frontend/.../models/productModel.dart` | Edit | Fix `_normalizeImageUrl` — sekarang gunakan `kBaseUrl` (dinamis) dan handle path tanpa leading `/` (e.g. `uploads/xxx.jpg`). Sebelumnya hardcode `http://localhost:8000` dan tidak handle kasus ini. |
| `backend/app/main.py` | Edit | Kurangi range unique_code dari `% 1000` (0-999) menjadi `% 100 + 1` (1-100) agar tidak terlalu besar dibanding harga item. |
| `frontend/.../screens/order/orderDetailScreen.dart` | Edit | (1) `await` pada tombol simulasi verifikasi, (2) tambah loading indicator saat konfirmasi terima pesanan, (3) tambah error handling yang proper. |
| `frontend/.../screens/order/orderListScreen.dart` | Edit | `await` pada tombol simulasi (verifikasi & kirim paket) + tambah error handling. |
| `frontend/.../provider/orderProvider.dart` | Edit | `updateStatus` sekarang rethrow exception agar UI bisa menangkap error. |

## Alasan

### Bug #1: Gambar produk tidak muncul
- **Root cause:** DB menyimpan image path sebagai `uploads/product_xxx.jpg` (tanpa leading `/`). `_normalizeImageUrl` hanya handle path dengan `/` prefix, sehingga path tanpa `/` diteruskan apa adanya → SmartImage menganggapnya sebagai asset lokal → gagal load.
- **Kenapa di pesanan gambar muncul?** Karena `ApiService.normalizeImage()` sudah handle semua kasus dengan benar.

### Bug #2: Total harga salah (Rp 1 jadi Rp 298)
- **Root cause:** `unique_code` digenerate dengan `sum(ord(char)) % 1000`, bisa menghasilkan angka hingga 999. Untuk item murah (Rp 1), unique code 297 membuat total = Rp 298.
- **Fix:** Cap ke `% 100 + 1` (range 1-100), lebih wajar sebagai kode unik pembayaran.

### Bug #3: Crash saat terima pesanan
- **Root cause:** Tombol simulasi memanggil `updateStatus` tanpa `await` → race condition saat UI rebuild. Tidak ada loading feedback → user menganggap app hang.
- **Fix:** Semua panggilan async di-`await`, tambah loading SnackBar, dan error handling yang proper.

## Catatan Penting

- Unique code untuk pesanan yang SUDAH dibuat sebelum fix ini tidak berubah — hanya pesanan baru yang akan mendapat unique code lebih kecil
- `flutter analyze` pass tanpa error baru (hanya info/warning pre-existing)
- Perlu rebuild Docker backend untuk apply perubahan unique_code: `docker-compose up --build -d`
