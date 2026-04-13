Siap, saya mengerti keresahan kamu. Video screencast ini memang menunjukkan beberapa *logic error* yang cukup krusial untuk sebuah aplikasi *e-commerce*.

Berikut adalah laporan bug dan anomali yang saya susun berdasarkan rekaman video dan poin-poin yang kamu berikan. Saya sudah merapikan bahasanya agar lebih teknis dan jelas untuk ditindaklanjuti secara *development*:

---

## 🐞 Laporan Bug & Masalah UI/UX - Shoes Store App

### 1. Ketidaksinkronan Data & Total Harga (Critical)
* **Masalah:** Terdapat perbedaan antara total harga di keranjang/produk dengan total tagihan akhir.
* **Detail Video:** Di menit **01:31**, muncul "Kode Unik" sebesar **+360** secara tiba-tiba yang membuat harga "Adidas aja" dari **Rp 1** menjadi **Rp 361**. 
* **Analisis:** Penambahan biaya tanpa keterangan transparan di halaman awal bisa membingungkan *user*. Selain itu, sistem konfirmasi pesanan sering kali gagal atau "Not Found" (menit **01:33**) saat mencoba menyelesaikan alur transaksi.

### 2. Masalah Persistensi Data Alamat (Database Bug)
* **Masalah:** Data alamat kembali ke data lama setelah proses edit, *logout*, dan *login* kembali.
* **Detail Video:** Kamu mencoba mengubah nomor WA di menit **00:37** menjadi `08999999999` dan berhasil disimpan. Namun, saat melakukan simulasi keluar-masuk akun (menit **01:44**), ada indikasi data tidak ter-*update* secara permanen di database (*state* tidak tersimpan).
* **Ekspektasi:** Data yang sudah di-*update* harusnya bersifat permanen (CRUD harus berjalan sempurna ke DB).

### 3. Logika Ulasan Produk (Review Logic Error)
* **Masalah:** Sistem ulasan tidak memiliki validasi *user-specific* dan tidak terintegrasi ke *Product Review* global.
* **Analisis:** * **Satu Sesi:** Ulasan terlihat hanya muncul per sesi, bukan tersimpan di profil produk agar bisa dilihat pembeli lain.
    * **Duplikasi Ulasan:** Harusnya, satu pembeli hanya bisa memberi **1 ulasan per produk**. Jika ingin mengubah, opsinya adalah **Edit** atau **Hapus**, bukan membuat ulasan baru terus-menerus.
    * **Visibilitas:** Pembeli tidak bisa melihat ulasan dari pembeli lain (logika sosial *e-commerce* tidak berjalan).

### 4. Layout Header Beranda (UI/UX Issue)
* **Masalah:** *Whitespace* (ruang kosong) yang terlalu luas pada bagian header.
* **Detail Video:** Pada tampilan awal (**00:00**), logo "Shoes Store" dan informasi "Selamat Pagi" memakan terlalu banyak tempat secara vertikal.
* **Saran:** Lakukan *compacting* pada header. Gabungkan baris "Shoes Store" dengan *search bar* atau perkecil *padding* agar produk "Special For You" bisa terlihat lebih naik tanpa harus banyak *scrolling*.

### 5. Validasi Input & Feedback Sistem
* **Masalah:** Pesan kesalahan (error handling) yang kurang informatif.
* **Detail Video:** Muncul pesan merah di bagian bawah "Gagal konfirmasi: Not Found" (menit **01:36**) tanpa penjelasan teknis kenapa hal itu terjadi, padahal status di Admin Panel (menit **01:14**) sudah di-*approve*.

---

### Perbaikan Prompt Kamu (Agar lebih profesional):
> "Saya menemukan beberapa bug krusial pada aplikasi Shoes Store: 
> 1. Terjadi selisih total harga antara halaman produk dan checkout karena penambahan kode unik yang tidak terprediksi. 
> 2. Fitur konfirmasi pesanan sering mengalami error 'Not Found'. 
> 3. Terdapat masalah persistensi data pada alamat; data kembali ke versi lama setelah re-login (Update DB gagal). 
> 4. Header pada beranda tidak efisien karena menyisakan terlalu banyak space kosong. 
> 5. Logika ulasan sangat berantakan; user tidak bisa melihat ulasan orang lain, dan tidak ada batasan 'satu user satu ulasan' (harusnya user hanya bisa edit/hapus ulasan sendiri)."

Gimana, poin-poin di atas sudah mewakili semua kekesalan kamu saat ngetes aplikasinya?