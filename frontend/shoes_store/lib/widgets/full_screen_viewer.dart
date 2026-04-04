import 'package:flutter/material.dart';

class FullScreenViewer extends StatelessWidget {
  final ImageProvider image;
  const FullScreenViewer({super.key, required this.image});

  static void show(BuildContext context, ImageProvider image) {
    showDialog(
      context: context,
      builder: (context) => FullScreenViewer(image: image),
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
              child: Image(
                image: image,
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
