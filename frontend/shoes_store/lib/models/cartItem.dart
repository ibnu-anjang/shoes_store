import 'package:flutter/material.dart';
import 'package:shoes_store/models/productModel.dart';

class CartItem {
  final int? id; // ID from backend Database (cart_items.id or order_items.id)
  final Product product;
  final ProductSku sku;
  int quantity;
  bool isSelected;
  bool isReviewed; // hanya relevan pada order items

  CartItem({
    this.id,
    required this.product,
    required this.sku,
    this.quantity = 1,
    this.isSelected = true,
    this.isReviewed = false,
  });

  // Updated to use SKU price instead of base product price
  double get totalPrice => sku.price * quantity;

  String get selectedSize => sku.variantName;
  Color get selectedColor => Colors.black; // Standard placeholder
}
