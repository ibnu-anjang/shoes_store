# Shoes Store - Flutter Frontend (Ultimate Setup Guide) 👟✨

Proyek ini adalah bagian **Frontend** dari Shoes Store. Jika kamu baru melakukan `git clone` dan melihat banyak **kode merah (error)** di editor kamu, jangan panik! Ikuti panduan pembersihan dan sinkronisasi "Level Dewa" di bawah ini.

---

## 🛠 Langkah 1: Persiapkan & Update Flutter SDK
Pastikan mesin tempur kamu up-to-date agar tidak ada *mismatch* versi SDK.

1.  **Cek Versi Sekarang**:
    ```bash
    flutter --version
    ```
    *Gunakan minimal Flutter SDK `^3.10.8`.*

2.  **Pastikan di Channel Stable**:
    ```bash
    flutter channel stable
    ```

3.  **Pastikan SDK Kamu Paling Baru**:
    ```bash
    flutter upgrade
    ```

4.  **Pastikan Semua Hijau (Checked)**:
    ```bash
    flutter doctor
    ```
    *Jika ada yang merah di `flutter doctor`, selesaikan dulu sesuai instruksi yang muncul di terminal.*

---

## 🔥 Langkah 2: Ritual Anti-Kode Merah (Ultimate Force Sync)
Langkah ini adalah cara paling ampuh jika `flutter pub get` biasa tidak mempan menghilangkan error.

1.  Buka terminal di folder: `frontend/shoes_store`.
2.  **Bersihkan Cache Build**:
    ```bash
    flutter clean
    ```
3.  **Hapus Sync File (Opsional tapi Ampuh)**:
    - Di Linux/Mac/Git Bash: `rm -rf .dart_tool pubspec.lock`
    - Di Windows (PowerShell): `Remove-Item -Recurse -Force .dart_tool, pubspec.lock`
4.  **Tarik Ulang Semua Package**:
    ```bash
    flutter pub get
    ```

---

## 🖥 Langkah 3: Perbaikan Sesuai Editor (IDE Fixing)
Jika terminal sudah OK tapi di editor (VS Code/Android Studio) masih ada garis merah:

### **A. Bagi Pengguna VS Code**
1.  Klik ikon ⚙️ (Gear) di pojok kiri bawah atau tekan `Ctrl + Shift + P`.
2.  Cari dan ketik: **"Dart: Restart Analysis Server"**.
3.  Tunggu sebentar sampai "Analyzing..." di status bar bawah selesai.

### **B. Bagi Pengguna Android Studio / IntelliJ**
1.  Klik menu **File** -> **Invalidate Caches...**.
2.  Centang semua pilihan, lalu klik **Invalidate and Restart**.
3.  Tunggu indexing selesai (progress bar di pojok kanan bawah).

---

## 🔗 Langkah 4: Konfigurasi Backend (Link to Database)
Aplikasi butuh tahu di mana lokasi Backend kamu berada agar data produk tidak kosong.

1.  Buka file: `lib/constant.dart`
2.  Cari variabel `kBaseUrl` di baris terakhir.
3.  Sesuaikan isinya:
    - **Emulator Android**: Tetap gunakan `http://10.0.2.2:8000`
    - **HP Asli (Real Device)**: Gunakan IP Laptop kamu (cek via `ipconfig` atau `ifconfig`), contoh: `http://192.168.1.10:8000`
    - **Domain Cloudflare**: Masukkan URL tunnel jika sudah hosting sendiri.

```dart
// Contoh di lib/constant.dart
const kBaseUrl = "http://10.0.2.2:8000"; // Ganti ini sesuai lokasi Backend!
```

---

## 🚀 Langkah 5: Running & Debugging
Jika semua langkah di atas sudah dilakukan, semua file `lib` harusnya sudah bersih dari garis merah.

```bash
flutter run
```

*Jika kamu running di **iOS (Mac)**, jangan lupa masuk ke folder `ios` dan jalankan `pod install`!*

Happy Coding & Debugging! 🚀📱
