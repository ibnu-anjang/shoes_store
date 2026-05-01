# Panduan Integrasi Ollama (Local AI) - Shoes Store

Dokumen ini menjelaskan cara memindahkan sistem Chatbot dari Google Gemini (Online) ke **Ollama (Local AI)** agar bisa berjalan tanpa internet/API Key dan lebih privat.

## 1. Persiapan Ollama di Arch Linux

### Instalasi
Buka terminal kamu dan jalankan:
```bash
sudo pacman -S ollama
```

### Menjalankan Service
Aktifkan service agar Ollama jalan di background:
```bash
sudo systemctl enable --now ollama
```

### Download Model
Untuk project Shoes Store, disarankan menggunakan salah satu model berikut:
*   **Llama3:** `ollama run llama3` (Paling cerdas, ~4.7GB)
*   **Mistral:** `ollama run mistral` (Cepat, ~4.1GB)
*   **Gemma 2B:** `ollama run gemma:2b` (Sangat ringan, cocok jika RAM terbatas)

---

## 2. Mengatur "Gaya Bicara" (Custom Modelfile)

Agar AI tidak bicara seperti robot umum dan benar-benar paham dia adalah asisten toko sepatu, kita perlu membuat **Modelfile**.

1.  Buat file baru bernama `ShoesBot.Modelfile`:
    ```dockerfile
    FROM llama3

    # Atur temperature (0.7 cukup kreatif tapi tetap akurat)
    PARAMETER temperature 0.7

    # Atur gaya bicara (System Prompt)
    SYSTEM """
    Kamu adalah 'Sneakerhead Assistant' dari toko Shoes Store. 
    Tugasmu adalah membantu pelanggan memilih sepatu yang cocok.
    Gayamu bicara harus ramah, gaul tapi tetap sopan, dan sangat paham tentang brand seperti Nike, Jordan, dan Adidas.
    Jika tidak tahu stok spesifik, sarankan pelanggan untuk cek tabel produk di halaman utama.
    Gunakan Bahasa Indonesia yang natural.
    """
    ```

2.  Daftarkan model baru ini ke Ollama:
    ```bash
    ollama create shoes-assistant -f ShoesBot.Modelfile
    ```

---

## 3. Integrasi ke Backend (FastAPI)

Ubah fungsi `chat_with_bot` di `backend/app/main.py`. Kamu perlu menginstal `httpx` terlebih dahulu (`pip install httpx`).

```python
import httpx

@app.post("/chat")
async def chat_with_bot(request: schemas.ChatRequest):
    ollama_url = "http://localhost:11434/api/chat"
    
    payload = {
        "model": "shoes-assistant",
        "messages": [
            {"role": "user", "content": request.message}
        ],
        "stream": False
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(ollama_url, json=payload, timeout=30.0)
            result = response.json()
            return {"reply": result['message']['content']}
    except Exception as e:
        return {"reply": "Maaf, sistem AI lokal sedang sibuk. Coba lagi nanti ya!"}
```

---

## 4. Pengaturan Penyimpanan & Resource

### Lokasi Model
Secara default di Linux, model disimpan di:
`/usr/share/ollama/.ollama/models`

Jika partisi `/` (root) kamu penuh, kamu bisa memindahkan lokasi model ke partisi lain (misal HDD/SSD eksternal) dengan mengatur environment variable:
```bash
# Tambahkan ini di .bashrc atau .zshrc
export OLLAMA_MODELS="/path/ke/folder/baru/kamu"
```

### Menghemat RAM
Secara default, Ollama akan tetap menyimpan model di RAM selama 5 menit setelah digunakan. Jika ingin AI langsung "tidur" setelah menjawab untuk menghemat RAM, tambahkan parameter `keep_alive: 0` di payload request API.

---

## 5. Tips Cek Pemakaian Disk (Maintenance)
Karena kamu tadi cek ada **6.1 GB** di Pacman Cache, jangan lupa rutin bersihkan agar ada ruang untuk model AI:
```bash
# Bersihkan semua kecuali 3 versi terakhir
sudo paccache -r

# Bersihkan total (sisakan yang terinstall saja)
sudo pacman -Sc
```
