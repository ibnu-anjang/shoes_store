import 'package:flutter/material.dart';

class Product {
  final String title;
  final String description;
  final String image;
  final String review;
  final String seller;
  final double price;
  final List<Color> colors;
  final String category;
  final double rate;
  int quantity;

  Product(
    {required this.title,
    required this.review,
    required this.description,
    required this.image,
    required this.price,
    required this.colors,
    required this.seller,
    required this.category,
    required this.rate,
    required this.quantity});
}

final List<Product> products = [
  Product(
    title: "Nike Air Max 270",
    description: "The Nike Air Max 270 is a stylish and comfortable sneaker designed for everyday wear. It features a large Air unit in the heel for cushioning and a sleek, modern design.",
    image: "images/shoe1.png",
    review: "4.5 (200 reviews)",
    seller: "Nike",
    price: 150.0,
    colors: [Colors.red, Colors.blue, Colors.green],
    category: "Sneakers",
    rate: 4.5,
    quantity: 1,
  ),
  Product(
    title: "Adidas Ultraboost",
    description: "The Adidas Ultraboost is a high-performance running shoe that combines comfort and style. It features Boost cushioning technology for energy return and a Primeknit upper for a snug fit.",
    image: "images/shoe2.png",
    review: "4.7 (150 reviews)",
    seller: "Adidas",
    price: 180.0,
    colors: [Colors.black, Colors.white, Colors.grey],
    category: "Running Shoes",
    rate: 4.7,
    quantity: 1,
  ),
  Product(
    title: "Nike Air Max 270",
    description: "The Nike Air Max 270 is a stylish and comfortable sneaker designed for everyday wear. It features a large Air unit in the heel for cushioning and a sleek, modern design.",
    image: "images/shoe1.png",
    review: "4.5 (200 reviews)",
    seller: "Nike",
    price: 150.0,
    colors: [Colors.red, Colors.blue, Colors.green],
    category: "Sneakers",
    rate: 4.5,
    quantity: 1,
  ),
  Product(
    title: "Adidas Ultraboost",
    description: "The Adidas Ultraboost is a high-performance running shoe that combines comfort and style. It features Boost cushioning technology for energy return and a Primeknit upper for a snug fit.",
    image: "images/shoe2.png",
    review: "4.7 (150 reviews)",
    seller: "Adidas",
    price: 180.0,
    colors: [Colors.black, Colors.white, Colors.grey],
    category: "Running Shoes",
    rate: 4.7,
    quantity: 1,
  ),
];