import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';

const kcontentColor = Color(0xffF5F5F5);
const kprimaryColor = Color(0xFFFF660e);

/// Format angka ke rupiah dengan pemisah ribuan. Contoh: 150000 → "Rp 150.000"
String formatRupiah(num amount) {
  final str = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
    count++;
  }
  return 'Rp ${buffer.toString().split('').reversed.join()}';
}

// --- KONFIGURASI URL BACKEND ---
// Ganti bagian ini sesuai domain Cloudflare kamu (tanpa https://)
const String _kCloudflareHost = "www.ibnuanjang.my.id";

/// URL backend yang dipakai seluruh app. Dipilih secara otomatis berdasarkan platform:
/// - Linux Desktop (debug) → http://localhost:8000
/// - Android Emulator (debug) → http://10.0.2.2:8000
/// - Android Device / Release Build → https://[cloudflare domain]
String get kBaseUrl {
  if (kIsWeb) return 'http://localhost:8000';

  if (kDebugMode) {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return 'http://localhost:8000'; // Flutter desktop dev → langsung ke Docker lokal
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android Emulator → loopback ke host
    }
  }

  // Production / release / device nyata → pakai Cloudflare Tunnel
  return 'https://$_kCloudflareHost';
}
