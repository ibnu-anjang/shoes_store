import 'package:flutter/material.dart';
import 'package:shoes_store/models/productModel.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  final Color selectedColor;
  int quantity;
  bool isSelected;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
    this.isSelected = true,
  });

  double get totalPrice => product.price * quantity;
}
