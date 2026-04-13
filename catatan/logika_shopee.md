1. Struktur Database Inti (Relational Schema)
Di standar industri, data historis tidak boleh berubah meskipun data master berubah. Misalnya, jika harga barang naik besok, harga di riwayat pesanan hari ini tidak boleh ikut naik.

A. Manajemen Produk & Variasi

products: Menyimpan informasi dasar. (id, name, description, category_id, is_active)

product_skus (Stock Keeping Unit): Ini rahasia variasi Shopee. Setiap kombinasi (misal: Baju Merah ukuran L) punya SKU sendiri.

id, product_id, variant_name (Merah-L)

price (Harga bisa beda tiap variasi)

stock_available (Stok yang bisa dibeli)

stock_reserved (Stok yang di-booking user yang belum bayar)

B. Keranjang Belanja

carts: id, user_id

cart_items: id, cart_id, sku_id, quantity, is_selected_for_checkout (Boolean).

C. Pesanan (Orders)

orders: id, user_id, total_amount, unique_code (kode unik transfer), status (UNPAID, VERIFYING, PAID, SHIPPED, COMPLETED, CANCELLED), created_at, expired_at.

order_items: id, order_id, sku_id, quantity, price_at_checkout (Harga saat user checkout, mengunci harga).

payment_confirmations: id, order_id, proof_image_url, status (PENDING, APPROVED, REJECTED).

2. Alur Logika: Keranjang (Add to Cart)
Saat user menekan tombol "Masukkan Keranjang", backend tidak boleh langsung menyimpan tanpa pengecekan.

Validasi: Cek tabel product_skus. Apakah stock_available > 0? Jika tidak, tolak request.

Upsert Logic: Jika barang (sku_id) yang sama sudah ada di cart_items user tersebut, cukup tambahkan quantity-nya. Jika belum, buat baris baru.

3. Alur Logika: Checkout & Locking Stok (Paling Krusial)
Ini adalah sistem penanganan Concurrency agar tidak terjadi barang habis tapi user tetap bisa beli (Overselling). Proses ini harus dibungkus dalam Database Transaction (jika satu langkah gagal, semua dibatalkan/di-rollback).

Hitung Total & Validasi Stok Ulang: Ambil barang dari keranjang yang is_selected_for_checkout = true. Cek ulang stoknya secara real-time.

Locking Stok (Penting): Kurangi stock_available, lalu tambahkan ke stock_reserved.

Ilustrasi: Baju A stok awal 10. User checkout 2. Maka stock_available = 8, stock_reserved = 2. Orang lain hanya bisa melihat sisa 8.

Create Order: Masukkan data ke tabel orders dengan status UNPAID. Atur expired_at menjadi +24 jam dari sekarang.

Create Order Items: Pindahkan data dari keranjang ke order_items, simpan juga price_at_checkout.

Clear Cart: Hapus barang yang di-checkout dari tabel cart_items.

4. Alur Logika: Auto-Cancel (Cron Job / Worker)
Karena Anda menggunakan pembayaran manual, batas waktu pembayaran sangat penting. Backend harus memiliki skrip yang berjalan di latar belakang (misal: setiap 5 menit).

Cari Data Expired: Query pesanan dengan status = UNPAID dan expired_at < waktu_sekarang.

Ubah Status: Update status order tersebut menjadi CANCELLED.

Release Stok: Kembalikan stok barang. Ambil dari stock_reserved, masukkan kembali ke stock_available.

5. Alur Logika: Verifikasi Pembayaran Manual (Admin Flow)
Karena tidak pakai payment gateway, ini alur penggantinya.

Upload Bukti (User): User upload gambar struk. Simpan URL gambar ke tabel payment_confirmations. Ubah status orders menjadi VERIFYING.

Verifikasi Admin: Admin melihat gambar di dashboard.

Jika Valid: Admin klik "Approve". Ubah status order jadi PAID. Ubah stock_reserved menjadi 0 (karena stok sudah sah terjual secara permanen).

Jika Tidak Valid: Admin klik "Reject". Status order kembali ke UNPAID (berikan alasan agar user bisa re-upload jika batas waktu belum habis).