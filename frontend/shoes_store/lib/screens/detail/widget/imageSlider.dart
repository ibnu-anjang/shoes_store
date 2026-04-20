import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';
import '../../../widgets/smartImage.dart';

class MyImageSlider extends StatelessWidget {
  final Function(int) onChange;
  final List<String> images;
  const MyImageSlider({
    super.key,
    required this.images,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: images.length,
        onPageChanged: onChange,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => FullScreenViewer.show(context, images[index]),
            child: Hero(
              tag: images[index],
              child: SmartImage(url: images[index]),
            ),
          );
        },
      ),
    );
  }
}