# Log: Admin Panel Upgrade — 2026-04-14

## Ringkasan
Upgrade besar-besaran admin panel dari versi sederhana (2 tab) ke panel profesional lengkap (4 tab).

## Perubahan Backend

### schemas.py
- Tambah `ProductUpdate` schema untuk endpoint edit produk

### main.py — 4 endpoint baru
1. `PUT /admin/products/{product_id}` — edit info produk (nama, harga, deskripsi, kategori)
2. `POST /admin/products/{product_id}/skus` — tambah varian ukuran baru ke produk
3. `DELETE /admin/skus/{sku_id}` — hapus varian ukuran produk
4. `GET /admin/users` — list semua pengguna dengan jumlah order & total belanja

## Perubahan Frontend (admin_panel/index.html)

### Fitur Baru
- **Tab Dashboard**: Revenue total, stats 4 kartu, breakdown status pesanan (bar chart sederhana), tabel 10 pesanan terbaru, warning stok menipis (≤5)
- **Tab Pesanan (diperkaya)**: Search by order ID/user ID, expandable row untuk lihat detail item + alamat + telepon
- **Tab Produk (diperkaya)**:
  - Form tambah produk: kategori dropdown (bukan text input) + deskripsi + SKU builder tabel (tambah/hapus ukuran dinamis)
  - Edit produk: modal dengan form nama/harga/kategori/deskripsi + manajemen SKU inline (tambah/hapus varian, update stok)
  - Filter produk: search nama + filter per kategori
  - Kolom total stok dengan warna (merah=habis, kuning=menipis, hijau=aman)
  - Expandable row untuk kelola SKU langsung dari tabel
- **Tab Pengguna**: Tabel username, email, total order, total belanja, foto profil
- **Kategori**: Dropdown dengan opsi default (Sneakers, Running, Casual, Formal, Sport, Sandals, Kids, Boots) + "Tambah Kategori Baru" tersimpan di localStorage
- **Badge sidebar**: Notifikasi VERIFYING count di nav Pesanan

## Status
Selesai. Backend syntax check: OK.
