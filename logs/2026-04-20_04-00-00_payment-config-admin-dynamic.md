# Activity Log — Payment Config: Admin Edit TF/QRIS + Dynamic Flutter
**Tanggal:** 2026-04-20 04:00

## Tujuan
Admin bisa edit info Transfer Bank (nama bank, nomor rekening, atas nama) dan upload foto QRIS dari panel admin tanpa menyentuh kode. Flutter mengambil config ini secara dinamis.

## Perubahan Backend

### models.py
- Tambah model `SiteSetting` (key-value store, primary key = key string)

### main.py
- Seed default values (`tf_bank_name`, `tf_account_number`, `tf_account_holder`, `qris_image`) saat startup jika belum ada
- `GET /payment-config` — public, kembalikan semua setting sebagai dict
- `PUT /admin/payment-config` — update field TF (dilindungi verify_admin)
- `POST /admin/payment-config/qris` — upload gambar QRIS baru, hapus file lama otomatis

## Perubahan Admin Panel (index.html)
- Tambah nav button "Pengaturan" di sidebar
- Tambah `tab-settings` dengan:
  - Form 3 field: Nama Bank, Nomor Rekening, Atas Nama + tombol "Simpan Info TF"
  - Section upload QRIS: preview current + drag-drop upload baru
- `TABS` array diupdate: ditambah `'settings'`
- `switchTab('settings')` → panggil `fetchPaymentConfig()`
- Fungsi baru: `fetchPaymentConfig()`, `saveTfConfig()`, `previewQris()`, `uploadQris()`

## Perubahan Flutter

### apiService.dart
- `getPaymentConfig()` — GET /payment-config, fallback ke hardcoded jika API gagal

### checkoutScreen.dart
- `_paymentConfig` Map + load di `initState()`
- `_buildMethodDetails()`: nama bank, nomor rek, atas nama dari config
- `_buildQrisWidget()`: tampilkan dari URL config atau fallback ke asset

### orderDetailScreen.dart
- `_paymentConfig` Map + `_loadPaymentConfig()` di `initState()`
- `_buildPaymentInstructions()`: info TF dari config
- `_buildQrisImage()`: Network image dari config URL atau fallback ke asset
- `_buildPriceCard()`: tambah baris "Kode Unik" dengan badge oranye (hanya tampil jika uniqueCode > 0, artinya TF/QRIS)

## Status
Flutter analyze: 0 error. Hot-reload cukup untuk Flutter. Backend perlu `make restart` (ada model baru + seed).
