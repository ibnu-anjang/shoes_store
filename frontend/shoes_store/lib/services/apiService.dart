import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/services/authService.dart';

class ApiService {
  static String get _baseUrl => AuthService.baseUrl;

  /// Kembalikan headers dengan Authorization Bearer token.
  static Future<Map<String, String>> _authHeaders({bool isJson = true}) async {
    final token = await AuthService.getToken();
    return {
      if (isJson) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static String normalizeImage(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '$_baseUrl$url';
    return '$_baseUrl/$url';
  }

  // --- USER PROFILE API ---

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final username = await AuthService.getUsername();
    if (username == null) return null;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$username'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error get user profile: $e');
    }
    return null;
  }

  // --- PRODUCT API ---

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error get products: $e');
    }
    return [];
  }

  // --- FAVORITE API ---

  static Future<List<Product>> getFavorites() async {
    try {
      final headers = await _authHeaders(isJson: false);
      final response = await http.get(Uri.parse('$_baseUrl/favorites'), headers: headers);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error get favorites: $e');
    }
    return [];
  }

  static Future<void> toggleFavorite(int productId) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: headers,
        body: jsonEncode({'product_id': productId}),
      );
    } catch (e) {
      debugPrint('Error toggle favorite: $e');
    }
  }

  // --- REMOTE CART API (New with Shopee Logic) ---

  static Future<void> addToCart(int skuId, int quantity) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/cart'),
        headers: headers,
        body: jsonEncode({'sku_id': skuId, 'quantity': quantity}),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCart() async {
     try {
       final headers = await _authHeaders(isJson: false);
       final response = await http.get(Uri.parse('$_baseUrl/cart'), headers: headers);
       if (response.statusCode == 200) {
         return jsonDecode(response.body);
       }
     } catch (e) {
       debugPrint("getCart error: $e");
     }
     return {};
  }

  static Future<void> updateCartItemQuantity(int cartItemId, int quantity) async {
    try {
      final headers = await _authHeaders(isJson: false);
      final response = await http.put(
        Uri.parse('$_baseUrl/cart/$cartItemId?quantity=$quantity'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> removeCartItem(int cartItemId) async {
    try {
      final headers = await _authHeaders(isJson: false);
      await http.delete(
        Uri.parse('$_baseUrl/cart/$cartItemId'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error remove cart item: $e');
    }
  }

  // --- ORDER & PAYMENT API ---

  static Future<List<Order>> getOrders() async {
    try {
      final headers = await _authHeaders(isJson: false);
      final response = await http.get(Uri.parse('$_baseUrl/orders'), headers: headers);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) {
          OrderStatus status;
          switch (json['status']) {
            case 'UNPAID': status = OrderStatus.menungguVerifikasi; break;
            case 'VERIFYING': status = OrderStatus.menungguVerifikasi; break;
            case 'PAID': status = OrderStatus.diproses; break;
            case 'SHIPPED': status = OrderStatus.dalamPengiriman; break;
            case 'DELIVERED': status = OrderStatus.diterima; break;
            case 'COMPLETED': status = OrderStatus.diterima; break;
            case 'CANCELLED': status = OrderStatus.dibatalkan; break;
            default: status = OrderStatus.menungguVerifikasi;
          }

          // Parse items with product data from backend
          List<CartItem> orderItems = [];
          if (json['items'] != null) {
            for (var itemJson in json['items']) {
              final product = Product(
                id: itemJson['product_id'] ?? 0,
                title: itemJson['product_name'] ?? 'Produk',
                description: '',
                specification: '',
                image: normalizeImage(itemJson['product_image'] ?? ''),
                review: '',
                type: '',
                price: (itemJson['price_at_checkout'] as num).toDouble(),
                colors: [],
                sizes: [itemJson['variant_name'] ?? ''],
                skus: [ProductSku(
                  id: itemJson['sku_id'] ?? 0,
                  variantName: itemJson['variant_name'] ?? '',
                  price: (itemJson['price_at_checkout'] as num).toDouble(),
                  stockAvailable: 0,
                )],
                category: '',
                rate: 4.8,
                quantity: 1,
              );
              orderItems.add(CartItem(
                product: product,
                sku: product.skus.first,
                quantity: itemJson['quantity'] ?? 1,
              ));
            }
          }

          final int uniqueCode = (json['unique_code'] as num?)?.toInt() ?? 0;
          final double total = (json['total'] as num).toDouble();
          // Backend: total = sum_of_items + unique_code
          final double subtotal = total - uniqueCode;

          return Order(
            id: json['id'].toString(),
            total: total,
            uniqueCode: uniqueCode,
            status: status,
            items: orderItems,
            subtotal: subtotal,
            ongkir: 0.0,
            alamat: json['shipping_address'] ?? 'Tersimpan di sistem',
            nomorWA: json['phone'] ?? '-',
            tanggal: DateTime.tryParse(json['tanggal'].toString()) ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error get orders: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String email,
    String? password,
    String? imagePath,
  }) async {
    final username = await AuthService.getUsername();
    if (username == null) throw Exception("Harus login!");

    final token = await AuthService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/profile/update'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['email'] = email;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }
    
    if (imagePath != null && !imagePath.startsWith('http')) {
      if (await File(imagePath).exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      }
    }
    
    var streamResponse = await request.send();
    var responseBody = await streamResponse.stream.bytesToString();
    
    if (streamResponse.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception("Gagal update profil: ${jsonDecode(responseBody)['detail'] ?? 'Unhandled error'}");
    }
  }

  static Future<Map<String, dynamic>> checkoutRemote(List<CartItem> items, String address, String phone) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/checkout'),
        headers: headers,
        body: jsonEncode({
          'address': address,
          'phone': phone,
          'items': items.map((e) => {
            'sku_id': e.sku.id,
            'quantity': e.quantity,
          }).toList(),
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['detail'] ?? "Gagal checkout");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['detail'] ?? "Gagal update status");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> confirmOrderReceived(String orderId) async {
    final headers = await _authHeaders(isJson: false);
    final http.Response response;
    try {
      response = await http
          .put(Uri.parse('$_baseUrl/orders/$orderId/received'), headers: headers)
          .timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      throw Exception('Gagal menghubungi server. Periksa koneksi internet kamu. ($e)');
    }
    if (response.statusCode != 200) {
      String detail;
      try {
        detail = jsonDecode(response.body)['detail'] ?? 'Gagal konfirmasi';
      } catch (_) {
        detail = 'Gagal konfirmasi (server error ${response.statusCode})';
      }
      throw Exception(detail);
    }
  }

  static Future<void> uploadPayment(String orderId, File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/orders/$orderId/pay'));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception("Gagal upload bukti!");
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- ADDRESS API ---

  static Future<List<dynamic>> getAddresses() async {
    try {
      final headers = await _authHeaders(isJson: false);
      final response = await http.get(Uri.parse('$_baseUrl/addresses'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error get addresses: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/addresses'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal menyimpan alamat');
    }
  }

  static Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/addresses/$id'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Gagal mengupdate alamat');
    }
  }

  static Future<void> deleteAddress(String id) async {
    final headers = await _authHeaders(isJson: false);
    final response = await http.delete(
      Uri.parse('$_baseUrl/addresses/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus alamat');
    }
  }

  // --- REVIEWS API ---

  static Future<List<dynamic>> getReviews(int productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reviews/$productId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error get reviews: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateReview(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    final reviewId = payload['id'].toString();
    var request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/reviews/$reviewId'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['rating'] = payload['rating'].toString();
    if (payload['comment'] != null) request.fields['comment'] = payload['comment'].toString();
    if (payload['image_path'] != null && !payload['image_path'].toString().startsWith('http')) {
      final String path = payload['image_path'].toString();
      if (await File(path).exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', path));
      }
    }
    var streamResponse = await request.send();
    var responseBody = await streamResponse.stream.bytesToString();
    if (streamResponse.statusCode == 200) return jsonDecode(responseBody);
    throw Exception(jsonDecode(responseBody)['detail'] ?? 'Gagal mengupdate ulasan');
  }

  static Future<void> deleteReview(String reviewId) async {
    final headers = await _authHeaders(isJson: false);
    final response = await http.delete(Uri.parse('$_baseUrl/reviews/$reviewId'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Gagal menghapus ulasan');
    }
  }

  static Future<Map<String, dynamic>> addReview(Map<String, dynamic> payload) async {
    final username = await AuthService.getUsername();
    if (username == null) throw Exception("Belum login");
    
    // We create a MultipartRequest because the backend expects Form data, not JSON
    final token = await AuthService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/reviews'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['id'] = payload['id'].toString();
    request.fields['product_id'] = payload['product_id'].toString();
    request.fields['rating'] = payload['rating'].toString();
    if (payload['comment'] != null) {
      request.fields['comment'] = payload['comment'].toString();
    }
    
    if (payload['image_path'] != null && !payload['image_path'].toString().startsWith('http')) {
      final String pathString = payload['image_path'].toString();
      if (await File(pathString).exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', pathString));
      }
    }
    
    var streamResponse = await request.send();
    var responseBody = await streamResponse.stream.bytesToString();
    
    if (streamResponse.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception("Gagal mengirim review: ${jsonDecode(responseBody)['detail'] ?? 'Unhandled error'}");
    }
  }

  static Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/promos'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error loading promos: $e");
    }
    return [];
  }
}
