import os
import re
import json
import logging
import urllib.request
from dotenv import load_dotenv

logger = logging.getLogger("shoes_store")

load_dotenv()

OLLAMA_BASE_URL = "http://172.18.0.1:11434"
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:1.5b")

SYSTEM_PROMPT = """Lo adalah SoleMate, asisten toko sepatu yang santai dan asik kayak temen deket.
Selalu pake "gue" dan "lo". Jawab singkat maks 3 kalimat. Jangan ngarang info produk."""

# Replacements to enforce casual Indonesian regardless of model output
_REPLACEMENTS = [
    (r'\bAnda\b', 'lo'),
    (r'\banda\b', 'lo'),
    (r'\bkamu\b', 'lo'),
    (r'\bKamu\b', 'lo'),
    (r'\bsaya\b', 'gue'),
    (r'\bSaya\b', 'Gue'),
    (r'\bkami\b', 'gue'),
    (r'\bKami\b', 'Gue'),
    (r'\bsilakan\b', 'ayo'),
    (r'\bSilakan\b', 'Ayo'),
    (r'\bterima kasih sudah\b', 'makasih udah'),
    (r'\bTerima kasih sudah\b', 'Makasih udah'),
    (r'\bHarap dicatat\b', 'BTW'),
    (r'\bperlu diingat\b', 'FYI'),
]


def _enforce_casual(text: str) -> str:
    for pattern, replacement in _REPLACEMENTS:
        text = re.sub(pattern, replacement, text)
    return text


class OllamaService:
    @staticmethod
    def generate_chat(message: str, product_context: str = "") -> str:
        url = f"{OLLAMA_BASE_URL}/api/chat"
        headers = {'Content-Type': 'application/json'}

        if product_context:
            user_message = f"Info produk toko:\n{product_context}\n\nPertanyaan: {message}"
        else:
            user_message = message

        data = {
            "model": OLLAMA_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": "halo"},
                {"role": "assistant", "content": "Eh halo! Lagi nyari sepatu nih? Gue siap bantu lo 👟"},
                {"role": "user", "content": "ada nike gak?"},
                {"role": "assistant", "content": "Ada dong! Mau yang buat lari apa casual nih?"},
                {"role": "user", "content": "mahal banget"},
                {"role": "assistant", "content": "Wkwk iya sih, tapi worth it kok. Budget lo sekitar berapa, gue cariin yang pas!"},
                {"role": "user", "content": user_message},
            ],
            "stream": False
        }

        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=45) as response:
                result = json.loads(response.read().decode())
                reply = result.get("message", {}).get("content", "Eh sori, gue lagi bengong bentar. Coba tanya lagi dong!")
                return _enforce_casual(reply)
        except Exception as e:
            logger.error(f"Ollama API error: {e}")
            return "Aduh, SoleMate lagi ada gangguan dikit nih. Bentar ya, coba lagi dalam beberapa detik!"
