import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/services/apiService.dart';

class ReviewItem {
  final String id;
  final String productId;
  final int orderItemId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? imagePath;
  final String? profilePicture;

  ReviewItem({
    required this.id,
    required this.productId,
    required this.orderItemId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.imagePath,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'orderItemId': orderItemId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
        'profilePicture': profilePicture,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'].toString(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString() ?? '0',
      orderItemId: (json['order_item_id'] as num?)?.toInt() ?? (json['orderItemId'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '0',
      userName: json['username'] ?? json['userName'] ?? (json['user_id'] != null ? "User #${json['user_id']}" : 'Pengguna'),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      imagePath: json['image_path'] ?? json['imagePath'],
      profilePicture: json['profile_picture'] ?? json['profilePicture'] ?? json['user_profile_image'],
    );
  }
}

class ReviewProvider extends ChangeNotifier {
  final Map<String, List<ReviewItem>> _reviews = {};
  bool _isLoading = false;
  String? _error;

  Map<String, List<ReviewItem>> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReviewProvider();

  static ReviewProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ReviewProvider>(context, listen: listen);
  }

  Future<void> loadProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final reviewsJson = await ApiService.getReviews(int.parse(productId));
      _reviews[productId] = reviewsJson.map((item) => ReviewItem.fromJson(item)).toList();
    } catch (e) {
      _error = "Gagal memuat ulasan";
      debugPrint("Gagal load reviews produk $productId: $e");
      _reviews.putIfAbsent(productId, () => []);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tambah review dengan optimistic insert + rollback jika server gagal.
  Future<void> addReview(ReviewItem review) async {
    _reviews.putIfAbsent(review.productId, () => []);
    _reviews[review.productId]!.insert(0, review);
    notifyListeners();

    try {
      await ApiService.addReview({
        "id": review.id,
        "product_id": int.parse(review.productId),
        "order_item_id": review.orderItemId,
        "rating": review.rating,
        "comment": review.comment,
        "image_path": review.imagePath,
        "profile_picture": review.profilePicture,
      });
      // Refresh dari server untuk sinkronisasi data
      await loadProductReviews(review.productId);
    } catch (e) {
      // Rollback optimistic insert
      _reviews[review.productId]!.removeWhere((r) => r.id == review.id);
      _error = "Gagal mengirim ulasan";
      debugPrint("Gagal kirim review ke server, rollback: $e");
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReview(ReviewItem review) async {
    if (_reviews.containsKey(review.productId)) {
      final index = _reviews[review.productId]!.indexWhere((item) => item.id == review.id);
      if (index != -1) {
        final old = _reviews[review.productId]![index];
        _reviews[review.productId]![index] = review;
        notifyListeners();
        try {
          await ApiService.updateReview({
            "id": review.id,
            "rating": review.rating,
            "comment": review.comment,
            "image_path": review.imagePath,
          });
          await loadProductReviews(review.productId);
        } catch (e) {
          _reviews[review.productId]![index] = old;
          _error = "Gagal mengupdate ulasan";
          notifyListeners();
          rethrow;
        }
      }
    }
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    if (_reviews.containsKey(productId)) {
      final idx = _reviews[productId]!.indexWhere((r) => r.id == reviewId);
      if (idx == -1) return;
      final old = _reviews[productId]![idx];
      _reviews[productId]!.removeAt(idx);
      notifyListeners();
      try {
        await ApiService.deleteReview(reviewId);
        await loadProductReviews(productId);
      } catch (e) {
        _reviews[productId]!.insert(idx, old);
        _error = "Gagal menghapus ulasan";
        notifyListeners();
        rethrow;
      }
    }
  }

  List<ReviewItem> getProductReviews(String productId) {
    return _reviews[productId] ?? [];
  }

  double getAverageRating(String productId, double initialRate) {
    final productReviews = _reviews[productId] ?? [];
    if (productReviews.isEmpty) return initialRate;

    double totalStars = 0;
    for (var review in productReviews) {
      totalStars += review.rating;
    }
    return totalStars / productReviews.length;
  }

  /// Wipe semua data saat logout agar tidak bocor ke akun berikutnya.
  void clearReviews() {
    _reviews.clear();
    _error = null;
    notifyListeners();
  }
}
