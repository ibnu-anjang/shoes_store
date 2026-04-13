import 'package:shoes_store/models/cartItem.dart';

enum OrderStatus {
  menungguVerifikasi,
  diproses,
  dalamPengiriman,
  diterima,
  dibatalkan,
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double ongkir;
  final double total;
  final int uniqueCode;
  final String alamat;
  final String nomorWA;
  final DateTime tanggal;
  OrderStatus status;
  String? resi;
  final String? paymentMethod;
  bool isReviewed;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.ongkir,
    required this.total,
    this.uniqueCode = 0,
    required this.alamat,
    required this.nomorWA,
    required this.tanggal,
    this.status = OrderStatus.diproses,
    this.resi,
    this.paymentMethod,
    this.isReviewed = false,
  });

  String get statusText {
    switch (status) {
      case OrderStatus.menungguVerifikasi:
        return 'Menunggu Pembayaran';
      case OrderStatus.diproses:
        return 'Pesanan Diproses';
      case OrderStatus.dalamPengiriman:
        return 'Dalam Pengiriman';
      case OrderStatus.diterima:
        return 'Paket Diterima';
      case OrderStatus.dibatalkan:
        return 'Pesanan Dibatalkan';
    }
  }

  String get statusEmoji {
    switch (status) {
      case OrderStatus.menungguVerifikasi:
        return '⏳';
      case OrderStatus.diproses:
        return '📦';
      case OrderStatus.dalamPengiriman:
        return '🚚';
      case OrderStatus.diterima:
        return '✅';
      case OrderStatus.dibatalkan:
        return '❌';
    }
  }
}
