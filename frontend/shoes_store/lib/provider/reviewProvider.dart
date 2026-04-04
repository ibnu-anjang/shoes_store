import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewItem {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? imagePath;

  ReviewItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'] ?? json['userName'], // Fallback for old data
      userName: json['userName'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      date: DateTime.parse(json['date']),
      imagePath: json['imagePath'],
    );
  }
}

class ReviewProvider extends ChangeNotifier {
  Map<String, List<ReviewItem>> _reviews = {};
  bool _isLoading = true;

  Map<String, List<ReviewItem>> get reviews => _reviews;
  bool get isLoading => _isLoading;

  ReviewProvider() {
    _loadReviews();
  }

  static ReviewProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ReviewProvider>(context, listen: listen);
  }

  Future<void> _loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reviewsJson = prefs.getString('local_reviews');
    
    if (reviewsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(reviewsJson);
      _reviews = decoded.map((key, value) {
        return MapEntry(
          key,
          (value as List).map((item) => ReviewItem.fromJson(item)).toList(),
        );
      });
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_reviews.map((key, value) {
      return MapEntry(key, value.map((item) => item.toJson()).toList());
    }));
    await prefs.setString('local_reviews', encoded);
  }

  void addReview(ReviewItem review) {
    if (!_reviews.containsKey(review.productId)) {
      _reviews[review.productId] = [];
    }
    _reviews[review.productId]!.insert(0, review);
    _saveReviews();
    notifyListeners();
  }

  void updateReview(ReviewItem review) {
    if (_reviews.containsKey(review.productId)) {
      final index = _reviews[review.productId]!.indexWhere((item) => item.id == review.id);
      if (index != -1) {
        _reviews[review.productId]![index] = review;
        _saveReviews();
        notifyListeners();
      }
    }
  }

  void deleteReview(String productId, String reviewId) {
    if (_reviews.containsKey(productId)) {
      _reviews[productId]!.removeWhere((item) => item.id == reviewId);
      _saveReviews();
      notifyListeners();
    }
  }

  List<ReviewItem> getProductReviews(String productId) {
    return _reviews[productId] ?? [];
  }

  double getAverageRating(String productId, double initialRate) {
    final productReviews = _reviews[productId] ?? [];
    if (productReviews.isEmpty) return initialRate;

    // Logic: Combine initial mock rating (assumed from 5 reviews) with new reviews
    // This makes the transition feel real (like Shopee/Tokped)
    double totalStars = initialRate * 5; 
    int totalCount = 5 + productReviews.length;

    for (var review in productReviews) {
      totalStars += review.rating;
    }

    return totalStars / totalCount;
  }
}
