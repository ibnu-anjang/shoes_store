# 📱 Panduan Setup AI Lokal + Build APK

> Status: Lengkap dengan troubleshooting Windows Release Build
> Update: 2026-04-14

---

## 🎯 Overview

Panduan ini mencakup:
1. ✅ Cara setup **LLM lokal** (Ollama) di backend
2. ✅ Cara **build APK** di Windows/Linux
3. ✅ **Troubleshoot** koneksi gagal di release build
4. ✅ **Analisis Cloudflare Tunnel** untuk production

---

## 1️⃣ SETUP AI LOKAL (Ollama + FastAPI Integration)

### Prerequisites
- **Ollama** installed ([download](https://ollama.ai))
- **8GB+ RAM** minimum
- **Model pilihan**: `mistral` (7B), `neural-chat` (7B), atau `llama2` (7B)

### Step 1: Download & Run Ollama

```bash
# 1. Download dan install dari ollama.ai
# 2. Setelah install, buka terminal baru dan jalankan:
ollama serve

# Output akan seperti:
# > Listening on 127.0.0.1:11434
```

### Step 2: Download Model (terminal baru)

```bash
# Pilih satu model (recommended: mistral untuk balance speed/quality)
ollama pull mistral          # ~4GB, responsif untuk chat
# ATAU
ollama pull neural-chat      # ~4.2GB, cocok untuk customer service
# ATAU  
ollama pull llama2           # ~3.8GB, cepat tapi kurang akurat
```

### Step 3: Update Backend FastAPI

**File**: `backend/requirements.txt`

Tambahkan:
```
ollama==0.1.25
```

**File**: `backend/app/routes/chat.py` (CREATE NEW)

```python
import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import ollama

router = APIRouter(prefix="/api/chat", tags=["chat"])
logger = logging.getLogger(__name__)

class ChatMessage(BaseModel):
    message: str
    conversation_history: list = []  # [{"role": "user", "content": "..."}, ...]

class ChatResponse(BaseModel):
    response: str
    tokens_used: int

@router.post("/ask")
async def ask_ai(payload: ChatMessage):
    """
    Chat dengan AI lokal via Ollama
    """
    try:
        # Build conversation context
        messages = payload.conversation_history + [
            {"role": "user", "content": payload.message}
        ]
        
        # Call Ollama (default: localhost:11434)
        response = ollama.chat(
            model="mistral",  # Ganti sesuai model yang di-pull
            messages=messages,
            stream=False
        )
        
        logger.info(f"AI response: {response['message']['content'][:100]}...")
        
        return ChatResponse(
            response=response['message']['content'],
            tokens_used=response.get('eval_count', 0)
        )
        
    except Exception as e:
        logger.error(f"Ollama error: {str(e)}")
        raise HTTPException(status_code=500, detail="AI server error")

@router.get("/models")
async def list_models():
    """List available models di Ollama"""
    try:
        response = ollama.list()
        return {"models": [m.model for m in response.models]}
    except Exception as e:
        logger.error(f"Failed to list models: {str(e)}")
        raise HTTPException(status_code=500, detail="Cannot connect to Ollama")
```

**File**: `backend/main.py` (ADD IMPORT)

```python
from app.routes import chat  # ADD THIS

app.include_router(chat.router)  # ADD THIS
```

### Step 4: Update Flutter untuk Chat AI

**File**: `frontend/shoes_store/lib/services/apiService.dart`

```dart
// ADD method di class ApiService:
Future<String> askAI(String message, List<Map<String, String>> history) async {
  try {
    final response = await http.post(
      Uri.parse('$kBaseUrl/api/chat/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'conversation_history': history,
      }),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('AI timeout - model sedang thinking'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? 'Tidak ada response';
    } else {
      throw Exception('AI error: ${response.body}');
    }
  } catch (e) {
    debugPrint('askAI error: $e');
    rethrow;
  }
}
```

### Step 5: Create Chat Screen (UI)

**File**: `frontend/shoes_store/lib/screens/chatAiScreen.dart` (CREATE NEW)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chatProvider.dart';
import '../constant.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({Key? key}) : super(key: key);

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: kprimaryColor,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: provider.messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = provider.messages[provider.messages.length - 1 - idx];
                    final isUser = msg['role'] == 'user';
                    
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? kprimaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Tanya AI assistant...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: kprimaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: provider.isLoading
                            ? null
                            : () {
                                if (_controller.text.isNotEmpty) {
                                  provider.addMessage(
                                    _controller.text,
                                    'user',
                                  );
                                  provider.askAI(_controller.text);
                                  _controller.clear();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**File**: `frontend/shoes_store/lib/providers/chatProvider.dart` (CREATE NEW)

```dart
import 'package:flutter/foundation.dart';
import '../services/apiService.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String? error;

  void addMessage(String content, String role) {
    messages.add({'role': role, 'content': content});
    notifyListeners();
  }

  Future<void> askAI(String message) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.askAI(message, messages);
      addMessage(response, 'assistant');
    } catch (e) {
      error = e.toString();
      addMessage('Error: $error', 'assistant');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    messages.clear();
    error = null;
    notifyListeners();
  }
}
```

### ✅ Test Ollama Integration

```bash
# 1. Start Ollama
ollama serve

# 2. Di terminal baru, test endpoint
curl -X POST http://localhost:8000/api/chat/ask \
  -H "Content-Type: application/json" \
  -d '{"message": "Halo, siapa namamu?", "conversation_history": []}'

# 3. Response akan seperti:
# {"response":"Halo! Saya adalah...","tokens_used":150}
```

---

## 2️⃣ BUILD APK DI WINDOWS

### Prerequisites
- **Android SDK** & **NDK** installed
- **Java 17+** installed
- **Flutter SDK** installed
- **Emulator atau Device** connected

### Step 1: Setup Key Signing (WAJIB untuk Release)

```bash
# Generate key (hanya 1x, simpan dengan aman!)
keytool -genkey -v -keystore ~/shoes_store_release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias shoes_store_key

# Atau di Windows PowerShell:
$JAVA_HOME = "C:\Program Files\Java\jdk-17"
& "$JAVA_HOME\bin\keytool" -genkey -v -keystore "$env:USERPROFILE\shoes_store_release.keystore" `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias shoes_store_key
```

**Isi form**:
```
Password: [pilih password kuat, mis: ShoeStore@2026]
First and last name: Shoes Store
Organization: Ibnu Anjang
City/Locality: Bandung
State/Province: Jawa Barat
Country code: ID
```

### Step 2: Setup Build Config

**File**: `frontend/shoes_store/android/key.properties` (CREATE NEW)

```properties
storePassword=ShoeStore@2026
keyPassword=ShoeStore@2026
keyAlias=shoes_store_key
storeFile=/path/to/shoes_store_release.keystore
```

**Di Windows**: Ganti path ke `C:/Users/[USERNAME]/shoes_store_release.keystore`

**File**: `frontend/shoes_store/android/app/build.gradle`

Cari section `android { }` dan replace dengan:

```gradle
android {
    compileSdkVersion 34
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
        }
    }
}
```

### Step 3: Build APK

```bash
# Clear build cache
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Output akan di: build/app/outputs/apk/release/app-release.apk
```

### Step 4: Test APK (di device/emulator)

```bash
# Install APK
adb install build/app/outputs/apk/release/app-release.apk

# Atau push langsung dari flutter
flutter install --release
```

---

## 3️⃣ TROUBLESHOOT: Windows Release Build Gagal Login/Register

### Root Cause

Release build di Windows konek ke `https://www.ibnuanjang.my.id` (dari constant.dart), tapi:

```dart
// Production / release / device nyata → pakai Cloudflare Tunnel
return 'https://$_kCloudflareHost';  // ← PERLU CLOUDFLARE TUNNEL AKTIF!
```

**Possible Issues:**

| Issue | Gejala | Solusi |
|-------|--------|--------|
| **Docker tidak running** | "Connection refused" | Mulai docker: `docker-compose up -d` |
| **Cloudflare Tunnel down** | "DNS resolution failed" | Cek token di docker-compose.yml |
| **Backend error** | "500 Server Error" | Cek logs: `docker logs my_uvicorn_app` |
| **SSL/Certificate** | "Handshake failed" | Pastikan HTTPS domain valid (Cloudflare) |
| **Network isolated** | "Timeout / No response" | Cek firewall, proxy settings |

### Solution: Multi-Environment Build

Untuk dev lebih mudah, setup **build flavors** sehingga bisa switch backend URL:

**File**: `frontend/shoes_store/lib/constant.dart`

```dart
// Ganti bagian kBaseUrl dengan logic yang lebih fleksibel
import 'package:flutter/foundation.dart';

enum Environment { dev, staging, production }

class Config {
  static Environment currentEnv = Environment.production;
  
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    
    if (kDebugMode) {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      return 'http://localhost:8000';
    }
    
    // For testing release, change this temporarily:
    // switch (currentEnv) {
    //   case Environment.dev:
    //     return 'http://localhost:8000';
    //   case Environment.staging:
    //     return 'https://staging.ibnuanjang.my.id';
    //   case Environment.production:
    //     return 'https://www.ibnuanjang.my.id';
    // }
    
    return 'https://www.ibnuanjang.my.id';
  }
}

// Replace semua `kBaseUrl` dengan `Config.baseUrl`
String get kBaseUrl => Config.baseUrl;
```

**Untuk test release dengan localhost:**

```dart
// Temporary: ubah ini untuk testing
static Environment currentEnv = Environment.dev;  // ← UBAH KE DEV
```

Setelah test, kembalikan ke `production`.

### Debug Checklist

```bash
# 1. Cek Docker status
docker ps
# Output harus ada: my_uvicorn_app, cloudflared_connector, shoes_store_db

# 2. Cek Cloudflare Tunnel logs
docker logs cloudflared_connector
# Harus ada: "Tunnel running at [URL]"

# 3. Cek backend logs
docker logs my_uvicorn_app
# Jika ada error, perbaiki & rebuild

# 4. Test backend endpoint langsung
curl https://www.ibnuanjang.my.id/api/products
# Jika timeout, tunnel down

# 5. Test dengan Android device (bukan emulator)
# Koneksi emulator ke localhost punya limitation
adb devices
adb install app-release.apk
```

---

## 4️⃣ ANALISIS: Cloudflare Tunnel untuk Production

### ✅ Kelebihan Cloudflare Tunnel

| Aspek | Status | Penjelasan |
|-------|--------|-----------|
| **Dapat handle traffic** | ✅ Excellent | Cloudflare infrastructure sangat kuat, cocok untuk production |
| **SSL/TLS** | ✅ Auto | Cloudflare handle SSL cert automatically |
| **DDoS Protection** | ✅ Included | Proteksi DDoS layer 3-7 included |
| **Geo-redundancy** | ✅ Yes | Traffic di-route lewat CDN terdekat |
| **Uptime** | ✅ 99.9%+ | SLA Cloudflare sangat stabil |
| **Concurrent Users** | ✅ Unlimited | Scales automatically dengan Cloudflare |

### ⚠️ Limitations & Considerations

```
1. **Token Security** ⚠️
   ❌ Token hardcoded di docker-compose.yml (BAHAYA!)
   ✅ Solusi: Simpan di .env file atau secrets management

2. **Backend Performance** ⚠️
   ❌ FastAPI lokal (1 instance) → bottleneck saat load tinggi
   ✅ Solusi: Scale dengan nginx/gunicorn workers, atau container orchestration

3. **Database** ⚠️
   ❌ MariaDB lokal single instance → single point of failure
   ✅ Solusi: Backup otomatis, atau managed database (AWS RDS, DigitalOcean)

4. **Mobile Network** ⚠️
   ❌ Release build hanya bisa login jika Cloudflare tunnel aktif
   ✅ Solusi: Implement fallback ke dev server, atau always keep tunnel active

5. **Cost** 💰
   ✅ Cloudflare Tunnel → FREE
   ⚠️ Tapi jika scale besar, perlu paid CDN/compute
```

### 🔒 Security Fix untuk Token

**File**: `backend/.env` (ADD)

```env
CLOUDFLARE_TOKEN=eyJhIjoiZDdjNDk2ZjlmOTEyODk5N2ZjOWYzNDI5Mzg2MWM0MzUiLCJ0IjoiYWUyMDQ1YmEtYjRmZS00YjQwLWEyYjktYzhlZDI4OGM4Y2Y5IiwicyI6Ik1XUTVOemxrT1RndE1ETTBNeTAwTmpGa0xUaGxZVGt0TldKbFpURTFObVE1TW1JMCJ9
```

**File**: `docker-compose.yml`

```yaml
tunnel:
  image: cloudflare/cloudflared:latest
  container_name: cloudflared_connector
  restart: always
  command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TOKEN}
  depends_on:
    - app
```

Jalankan:
```bash
docker-compose up -d
```

### 📊 Recommended Architecture untuk Production

```
┌─────────────────────┐
│   Flutter APK       │
│  (Mobile App)       │
└──────────┬──────────┘
           │ HTTPS
           ▼
┌─────────────────────────────────────┐
│     Cloudflare (CDN + Protection)   │
│  www.ibnuanjang.my.id               │
└──────────┬──────────────────────────┘
           │ HTTP (Tunnel)
           ▼
┌─────────────────────────────────────┐
│    FastAPI Backend (Docker)         │
│    - Cloudflare Tunnel              │
│    - Gunicorn (4+ workers)          │
│    - Rate limiting middleware       │
└──────────┬──────────────────────────┘
           │ SQL
           ▼
┌─────────────────────────────────────┐
│  MariaDB (Backup + Replication)     │
│  - Daily backups                    │
│  - Read replicas (optional)         │
└─────────────────────────────────────┘
```

---

## 5️⃣ QUICK CHECKLIST SEBELUM PRODUCTION

- [ ] **Android**
  - [ ] Build APK signed
  - [ ] Test di real device (bukan emulator)
  - [ ] Cek UI scaling di berbagai ukuran screen
  - [ ] Test upload gambar, checkout, pembayaran
  
- [ ] **Backend**
  - [ ] Semua `print()` ganti dengan `logging`
  - [ ] Database backup script ready
  - [ ] Gunicorn workers > 1
  - [ ] Rate limiting middleware active
  
- [ ] **Infrastructure**
  - [ ] Cloudflare Tunnel token di `.env`, bukan hardcoded
  - [ ] SSL/TLS enabled (Cloudflare)
  - [ ] Monitoring & logging setup (optional tapi rekomen)
  - [ ] Database backup automation
  
- [ ] **Security**
  - [ ] CORS policy correct
  - [ ] Password hashing (bcrypt)
  - [ ] No secrets di repo
  - [ ] API rate limiting

---

## 📞 Support Commands

```bash
# View logs real-time
docker-compose logs -f

# Restart all services
docker-compose restart

# Rebuild backend
docker-compose build --no-cache app

# Clear Flutter cache
flutter clean && flutter pub get

# Check device connectivity
adb devices

# Uninstall APK dari device
adb uninstall com.example.shoes_store
```

---

**Last Updated**: 2026-04-14
**Status**: Ready for production setup ✅
