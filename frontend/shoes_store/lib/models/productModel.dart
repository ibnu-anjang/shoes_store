import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';

class ProductSku {
  final int id;
  final String variantName;
  final double price;
  final int stockAvailable;

  final String? colorHex; // Hex color linked to this SKU
  
  ProductSku({
    required this.id,
    required this.variantName,
    required this.price,
    required this.stockAvailable,
    this.colorHex,
  });

  factory ProductSku.fromJson(Map<String, dynamic> json) {
    return ProductSku(
      id: json['id'] ?? 0,
      variantName: json['variant_name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stockAvailable: json['stock_available'] ?? 0,
      colorHex: json['color_hex'],
    );
  }
}

class Product {
  final int id;
  final String title;
  final String description;
  final String specification;
  final String image;
  final String review;
  final String type;
  final double price;
  final List<Color> colors;
  final List<String> sizes; // Deprecated: use skus instead for real logic
  final List<ProductSku> skus;
  final List<String> gallery; // Gallery image URLs
  final List<String> generalGallery; // Images available for all colors
  final Map<Color, List<String>> colorGalleries; // Images restricted to specific colors
  final String category;
  final double rate;
  int quantity;

  Product({
    required this.id,
    required this.title,
    required this.review,
    required this.description,
    required this.specification,
    required this.image,
    required this.price,
    required this.colors,
    required this.sizes,
    required this.skus,
    required this.gallery,
    this.generalGallery = const [],
    this.colorGalleries = const {},
    required this.type,
    required this.category,
    required this.rate,
    required this.quantity,
  });

  static String _normalizeImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    if (url.startsWith('assets/')) return url; // Flutter local asset, jangan dinormalisasi
    if (url.startsWith('/')) return '$kBaseUrl$url';
    return '$kBaseUrl/$url';
  }

  String getEffectiveThumbnail(Color? color) {
    if (color == null) return image;
    
    // Look for color in colorGalleries
    // Because Color objects can be different instances with same value, 
    // we should find by hex match if direct key lookup fails.
    if (colorGalleries.containsKey(color)) {
      final list = colorGalleries[color]!;
      if (list.isNotEmpty) return list.first;
    }
    
    // Fallback: search by value match
    final matchedKey = colorGalleries.keys.firstWhere(
      (k) => k.value == color.value,
      orElse: () => Colors.transparent,
    );
    if (matchedKey != Colors.transparent) {
      final list = colorGalleries[matchedKey]!;
      if (list.isNotEmpty) return list.first;
    }

    return image;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    var skusList = (json['skus'] as List?)?.map((i) => ProductSku.fromJson(i)).toList() ?? [];
    
    // Parse colors from API
    List<Color> colorList = [];
    if (json['colors'] != null) {
      for (var c in json['colors']) {
        final hex = c['color_hex'];
        if (hex != null) {
          Color cParsed = hexToColor(hex);
          colorList.add(cParsed);
        }
      }
    }
    if (colorList.isEmpty) colorList = [Colors.black, Colors.white, Colors.grey]; // Fallback
    
    // Parse gallery
    List<String> galleryList = [];
    List<String> generalGalleryList = [];
    Map<Color, List<String>> parsedColorGalleries = {};

    if (json['gallery'] != null) {
      for (var img in json['gallery']) {
        final url = img['image_url'];
        final colorHex = img['color_hex'];
        
        if (url != null) {
          final normalized = _normalizeImageUrl(url);
          galleryList.add(normalized);
          
          if (colorHex == null || colorHex.toString().isEmpty) {
            generalGalleryList.add(normalized);
          } else {
            Color c = hexToColor(colorHex);
            if (!parsedColorGalleries.containsKey(c)) {
               parsedColorGalleries[c] = [];
            }
            parsedColorGalleries[c]!.add(normalized);
          }
        }
      }
    }
    // Tambahkan main image ke depan gallery jika belum ada
    if (json['image'] != null && !generalGalleryList.contains(_normalizeImageUrl(json['image']))) {
      generalGalleryList.insert(0, _normalizeImageUrl(json['image']));
    }
    if (json['image'] != null && !galleryList.contains(_normalizeImageUrl(json['image']))) {
      galleryList.insert(0, _normalizeImageUrl(json['image']));
    }

    return Product(
      id: json['id'] ?? 0,
      title: json['name'] ?? '',
      description: json['description'] ?? '',
      specification: json['specification'] ?? "No specification provided.",
      image: _normalizeImageUrl(json['image'] ?? ''),
      review: "0 Reviews", 
      type: json['category'] ?? "Sneakers",          
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      colors: colorList,
      sizes: skusList.map((s) => s.variantName).toList(), 
      skus: skusList,
      gallery: galleryList,
      generalGallery: generalGalleryList,
      colorGalleries: parsedColorGalleries,
      category: json['category'] ?? "Shoes",        
      rate: (json['rating'] as num?)?.toDouble() ?? 0.0,                 
      quantity: 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': title,
        'description': description,
        'price': price,
      };
}

Color hexToColor(String hex) {
  try {
    if (hex.startsWith('0x')) {
      return Color(int.parse(hex));
    } else if (hex.startsWith('#')) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }
    return Color(int.parse('0xFF' + hex));
  } catch (e) {
    return Colors.black;
  }
}

String colorToHex(Color color) {
  return '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

// Global products list - will be populated from API, but keep as fallback
List<Product> products = [];