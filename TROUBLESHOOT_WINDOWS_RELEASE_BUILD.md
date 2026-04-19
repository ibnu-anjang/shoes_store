# 🔧 Troubleshoot: Windows Release Build Gagal Login/Register

## 🎯 Root Cause Analysis

Saat Anda build **release APK di Windows**, aplikasi langsung **HANYA konek ke `https://www.ibnuanjang.my.id`** (bukan localhost), karena:

```dart
// File: constant.dart - line 29-42
String get kBaseUrl {
  if (kIsWeb) return 'http://localhost:8000';
  
  if (kDebugMode) {  // ← Ini FALSE saat build release!
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
  }
  
  // Production / release / device nyata → pakai Cloudflare Tunnel
  return 'https://$_kCloudflareHost';  // ← LANGSUNG KE INI!
}
```

**Hasilnya:**
```
Release Build di Windows:
┌─────────────────┐
│ Flutter APK     │
│ (kDebugMode=F)  │
└────────┬────────┘
         │ HTTPS https://www.ibnuanjang.my.id
         ↓
    ❌ Cloudflare Tunnel HARUS active!
    ❌ Jika tidak, akan timeout/connection refused
```

---

## 🔍 Diagnosis Cepat: Mana Penyebabnya?

### Test 1: Cek Docker Status

```bash
docker ps
```

**Output harus seperti ini:**
```
CONTAINER ID   IMAGE                      STATUS
xyz123         cloudflare/cloudflared     Up 2 days
abc456         shoes_store_db             Up 2 days
def789         my_uvicorn_app             Up 2 days
ghi012         phpmyadmin:latest          Up 2 days
```

❌ **Jika ada yang tidak Up:**
```bash
# Restart semua
docker-compose up -d

# Atau rebuild jika ada error
docker-compose build --no-cache
docker-compose up -d
```

---

### Test 2: Cek Cloudflare Tunnel Status

```bash
docker logs cloudflared_connector | tail -20
```

**✅ Output yang benar:**
```
2026-04-14T10:30:45Z INF |  cloudflared  | Tunnel running at https://www.ibnuanjang.my.id
2026-04-14T10:30:45Z INF |  cloudflared  | Connected to origin
```

**❌ Output yang salah (ada error):**
```
2026-04-14T10:30:45Z ERR |  cloudflared  | Invalid token
2026-04-14T10:30:45Z ERR |  cloudflared  | Connection refused
```

**Solusi jika ada error:**
```bash
# 1. Regenerate Cloudflare token
# - Login ke https://dash.cloudflare.com/
# - Cari Tunnel "shoes_store" (atau buat baru)
# - Copy token

# 2. Update docker-compose.yml
# Replace token lama dengan token baru

# 3. Rebuild tunnel
docker-compose up -d tunnel
```

---

### Test 3: Cek Backend Connection

```bash
# Test via curl
curl -v https://www.ibnuanjang.my.id/api/products
```

**✅ Output yang benar:**
```
* Connected to www.ibnuanjang.my.id (1.2.3.4) port 443
> GET /api/products HTTP/2
< HTTP/2 200
```

**❌ Output yang salah:**
```
* Failed to connect to www.ibnuanjang.my.id port 443
* Connection refused
```

**Solusi:**
```bash
# Check backend logs
docker logs my_uvicorn_app | tail -50

# Jika ada error di backend, rebuild
docker-compose build app
docker-compose up -d app
```

---

## 🛠️ Solusi Berdasarkan Penyebab

### Case 1: Docker Tidak Running

**Gejala:**
- ❌ `docker ps` error atau kosong
- ❌ APK gagal login: "Network error" / "Connection refused"

**Solusi:**

```bash
# Windows (PowerShell/CMD)
cd /path/to/shoes_store
docker-compose up -d

# Linux/Mac
docker-compose up -d

# Tunggu ~30 detik sampai semua service healthy
sleep 30

# Cek status
docker ps
```

**Verifikasi:**
```bash
# Test API endpoint
curl https://www.ibnuanjang.my.id/api/products
# Harus return JSON products list
```

---

### Case 2: Cloudflare Token Invalid / Expired

**Gejala:**
- ❌ APK timeout saat login
- ❌ `docker logs cloudflared_connector` ada error "Invalid token"
- ❌ `curl` ke domain timeout (DNS resolve fail)

**Solusi:**

```bash
# 1. Login ke Cloudflare Dashboard
# https://dash.cloudflare.com/ → Zero Trust → Tunnels

# 2. Cari tunnel "shoes_store" atau buat baru
# 3. Click tunnel → Copy token bagian "Run connector"

# 4. Edit docker-compose.yml
nano docker-compose.yml

# 5. Cari section tunnel, ganti token:
# Dari:
# command: tunnel --no-autoupdate run --token [TOKEN_LAMA]
# Ke:
# command: tunnel --no-autoupdate run --token [TOKEN_BARU]

# 6. Update tunnel service
docker-compose up -d tunnel

# 7. Verifikasi logs
docker logs cloudflared_connector | grep "running at"
```

**Expected output:**
```
INF |  cloudflared  | Tunnel running at https://www.ibnuanjang.my.id
```

---

### Case 3: Backend Error (500)

**Gejala:**
- ✅ APK konek ke server (bukan timeout)
- ❌ Tapi error saat login: "500 Server Error"

**Solusi:**

```bash
# 1. Check backend logs
docker logs my_uvicorn_app | tail -100

# Cari pattern error di log (mis: "Traceback", "Error", "Exception")

# 2. Common errors:

# A. Database connection failed
# Error: "2026-04-14 10:30:45 - sqlalchemy.exc.OperationalError"
# Fix:
docker-compose up -d db
sleep 10
docker-compose up -d app

# B. Environment variable missing
# Error: "KeyError: 'DATABASE_URL'"
# Fix:
# Cek backend/.env, pastikan semua variable ada

# C. Import error / dependency missing
# Error: "ModuleNotFoundError: No module named 'X'"
# Fix:
docker-compose build --no-cache app
docker-compose up -d app

# 3. Jika sudah tahu error, fix code kemudian rebuild:
docker-compose build app
docker-compose up -d app
```

---

### Case 4: Network Isolated / Firewall Blocking

**Gejala:**
- ❌ APK bisa konek API lokal (http://localhost:8000) ✅
- ❌ Tapi APK gagal konek HTTPS domain
- ❌ `curl https://domain` timeout

**Solusi:**

```bash
# 1. Test dari device yang sama dengan APK
# Buka browser di device → https://www.ibnuanjang.my.id/api/products
# Jika loading lama/error → DNS/firewall issue

# 2. Check Windows Firewall
# Windows → Settings → Privacy & Security → Windows Defender Firewall
# → Allow app through firewall
# ✅ Check Docker Desktop, flutter, adb

# 3. Check antivirus/VPN
# Matikan antivirus temporary → coba login lagi
# Jika langsung berhasil → antivirus blocking HTTPS traffic

# 4. Check WiFi router (jika pakai WiFi)
# Login ke router → check HTTPS traffic allow?
# Atau try dengan mobile data (jika ada)

# 5. Force IPv4 DNS
# Di device Android:
# Settings → Network → Advanced → IP settings
# → Set static DNS: 8.8.8.8 (Google)
```

---

### Case 5: APK Stale / Cache Issues

**Gejala:**
- ✅ Debug build login OK
- ❌ Release build gagal
- ✅ Tapi docker/backend semua OK

**Solusi:**

```bash
# 1. Clean Flutter project
cd frontend/shoes_store
flutter clean
flutter pub get

# 2. Rebuild APK
flutter build apk --release

# 3. Uninstall lama, install baru
adb uninstall com.example.shoes_store
adb install build/app/outputs/apk/release/app-release.apk

# 4. Atau install langsung
flutter install --release
```

---

## 🚀 Quick Fix: Temporary Use Localhost Instead

Jika mau test cepat tanpa khawatir Cloudflare tunnel:

**File**: `frontend/shoes_store/lib/constant.dart`

```dart
// Temporary fix untuk testing release build
String get kBaseUrl {
  // TEMPORARY: test dengan localhost
  return 'http://localhost:8000';
  
  // Production fallback:
  // return 'https://$_kCloudflareHost';
}
```

**Tapi perhatian:**
⚠️ **HANYA untuk testing di development machine**
⚠️ **Jangan deploy ke production dengan ini**
⚠️ **Real device tidak bisa akses localhost**

Setelah test selesai, **HARUS kembalikan ke Cloudflare URL**:

```dart
String get kBaseUrl {
  // Back to production
  if (kDebugMode) {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  return 'https://$_kCloudflareHost';  // ← PRODUCTION
}
```

---

## ✅ Verification Checklist

Setelah fix, cek semua ini:

- [ ] **Docker**
  ```bash
  docker ps
  # Semua 4 service ada dan "Up"
  ```

- [ ] **Cloudflare Tunnel**
  ```bash
  docker logs cloudflared_connector | grep "running at"
  # Ada output: "Tunnel running at https://..."
  ```

- [ ] **Backend API**
  ```bash
  curl https://www.ibnuanjang.my.id/api/products
  # Return JSON, bukan error
  ```

- [ ] **Flutter APK Release**
  ```bash
  flutter clean
  flutter build apk --release
  adb install build/app/outputs/apk/release/app-release.apk
  ```

- [ ] **Manual Test di Device**
  - ✅ Buka APK
  - ✅ Test login dengan account yang valid
  - ✅ Test register dengan email/username baru
  - ✅ Test browse products, add to cart
  - ✅ Test checkout & order

---

## 📊 Decision Tree: Mana yang harus di-fix?

```
APK gagal login/register?
│
├─ Bisa konek lokal (http://localhost:8000)? ✅
│  └─ Berarti kode OK, hanya issue prod URL
│     └─ Go to Case 1-5 ↑
│
└─ Gagal keduanya (lokal + prod)? ❌
   └─ Ada bug di authentication logic
      └─ Check logcat: adb logcat | grep -i "error"
```

---

## 📞 Debug Commands Summary

```bash
# Clear semua dan start fresh
docker-compose down -v
docker-compose up -d

# View all logs
docker-compose logs -f

# Rebuild backend
docker-compose build app && docker-compose up -d

# Test endpoint
curl https://www.ibnuanjang.my.id/api/products

# Rebuild & reinstall APK
flutter clean && flutter build apk --release
adb install build/app/outputs/apk/release/app-release.apk

# View APK logs live
adb logcat | grep -i "flutter\|error"

# Uninstall APK
adb uninstall com.example.shoes_store
```

---

**Last Updated**: 2026-04-14
**Tested on**: Windows 10/11 + Android device
**Status**: Ready for production testing ✅
