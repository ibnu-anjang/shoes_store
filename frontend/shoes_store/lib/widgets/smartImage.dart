import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class SmartImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: (height ?? 60) * 0.4),
  );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2)
            )
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else if (url.startsWith('/')) {
      // Local file loading
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      // Offline Asset fallback
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }
}
