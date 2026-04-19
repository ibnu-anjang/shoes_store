# Log: Camera/Gallery Picker untuk Foto Profil di Review Screen

**Tanggal**: 2026-04-19

## Perubahan yang Dilakukan

### 1. `lib/models/userModel.dart` (baru)
- Tambah `UserModel` dengan field: `id`, `username`, `email`, `profilePicture`
- Termasuk `fromJson` dan `copyWith`

### 2. `lib/services/apiService.dart`
- Tambah method `uploadProfilePicture(String imagePath)` menggunakan `http.MultipartRequest`
- POST ke `/profile/update` dengan file multipart

### 3. `lib/screens/review/reviewScreen.dart`
- Tambah state: `_profileImagePath`, `_isUploadingProfile`
- `initState`: load foto profil dari `UserProvider`
- `_showProfileImagePicker()`: ModalBottomSheet dengan opsi Kamera dan Galeri
- `_pickProfileImage(ImageSource)`: ambil foto → upload → update `UserProvider` & state lokal
- `_buildProfileAvatar()`: CircleAvatar radius 42 + kamera icon badge di kanan bawah
- Review form sekarang dimulai dengan avatar profil user di bagian atas

## Catatan
- Upload tetap menggunakan endpoint `/profile/update` yang sudah ada
- Jika upload gagal, foto lokal di-reset (tidak tersimpan)
- ModalBottomSheet menggunakan `_pickerOption` widget helper untuk tampilan bersih
