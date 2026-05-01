import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';
import '../../../widgets/smartImage.dart';

class MyImageSlider extends StatelessWidget {
  final Function(int) onChange;
  final List<String> images;
  final PageController? controller;
  
  const MyImageSlider({
    super.key,
    required this.images,
    required this.onChange,
    this.controller,
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
        controller: controller,
        itemCount: images.length,
        physics: const BouncingScrollPhysics(),
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