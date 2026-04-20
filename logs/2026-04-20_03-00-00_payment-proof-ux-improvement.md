# Activity Log — Payment Proof UX Improvement
**Tanggal:** 2026-04-20 03:00

## Tujuan
Meningkatkan UX pada screen Detail Pesanan untuk alur upload bukti pembayaran, visibilitas tombol batal, dan handling COD.

## Perubahan Backend

### main.py
- `upload_payment_proof`: Izinkan re-upload saat status `VERIFYING` (sebelumnya hanya `UNPAID`)
- `cancel_order`: Izinkan pembatalan saat status `PAID` (diproses) — sebelumnya hanya UNPAID/VERIFYING

## Perubahan Flutter

### orderDetailScreen.dart (full rewrite UX)

1. **Image Source Bottom Sheet** (`_showImageSourceSheet`):
   - Pilihan galeri ATAU kamera via modal bottom sheet
   - Tampilan dua tombol besar dengan ikon yang jelas

2. **Preview Anti-Salah Kirim**:
   - Foto yang dipilih tampil sebagai full preview sebelum konfirmasi
   - Badge "Ganti Foto" overlay di pojok kanan atas preview
   - Indikator hijau "Foto siap dikirim. Pastikan gambar sudah benar!"
   - Tombol berubah menjadi abu-abu saat belum pilih foto (disabled state)

3. **Tombol "Konfirmasi Pembayaran"** (bukan "Kirim Bukti"):
   - Nama tombol lebih intuitif
   - Mode edit: berubah jadi "Perbarui Bukti Pembayaran"

4. **Re-upload untuk VERIFYING** (`_buildProofSentCard`):
   - Tampilkan card teal "Bukti Pembayaran Terkirim" saat status menungguVerifikasi
   - Tombol "Edit Bukti Pembayaran" toggle `_isEditMode = true`
   - Upload section muncul ketika edit mode aktif
   - Tombol "Batal Edit" untuk kembali ke view normal

5. **COD Processing Card** (`_buildCodProcessingCard`):
   - Card hijau khusus untuk pesanan COD yang sudah diproses
   - Pesan: "Pembayaran dilakukan saat paket tiba di tangan Anda."

6. **Cancel Button diperluas**:
   - Sebelumnya: hanya untuk `unpaid` dan `menungguVerifikasi`
   - Sekarang: juga untuk `diproses` (PAID) — sesuai request user
   - Tetap disembunyikan untuk `dalamPengiriman` dan `diterima`

7. **Semua `withOpacity` → `withValues(alpha:)`** (deprecated fix)

## Status
Flutter analyze: 0 error (62 info pre-existing). Hot-reload langsung efektif — tidak perlu `make rebuild`.
