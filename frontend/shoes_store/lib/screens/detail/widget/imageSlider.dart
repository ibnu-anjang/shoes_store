import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';
import '../../../widgets/smartImage.dart';

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
        itemCount: 1, // Batasi jumlah gambar agar tidak bisa digeser tanpa henti
        onPageChanged: onChange,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => FullScreenViewer.show(context, image),
            child: Hero(
              tag: image,
              child: SmartImage(url: image),
            ),
          );
        },
      ),
    );
  }
}