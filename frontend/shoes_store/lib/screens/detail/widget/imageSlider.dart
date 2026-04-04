import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/full_screen_viewer.dart';

class MyImageSlider extends StatelessWidget {
  final Function(int) onChange;
  final String image;
  const MyImageSlider({
    super.key,
    required this.image,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        onPageChanged: onChange,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => FullScreenViewer.show(context, AssetImage(image)),
            child: Hero(
              tag: image,
              child: Image.asset(image),
            ),
          );
        },
      ),
    );
  }
}