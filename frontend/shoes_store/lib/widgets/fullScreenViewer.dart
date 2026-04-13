import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/smartImage.dart';

class FullScreenViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenViewer({super.key, required this.imageUrl});

  static void show(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => FullScreenViewer(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: SmartImage(
                url: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
