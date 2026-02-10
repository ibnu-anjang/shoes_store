import 'package:flutter/material.dart';

class ImageSlider extends StatelessWidget {
  final Function (int) onChange;
  final int currentSlide;
  const ImageSlider({
    super.key,
    required this.currentSlide,
    required this.onChange,
    });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: PageView(
              scrollDirection: Axis.horizontal,
              allowImplicitScrolling: true,
              onPageChanged: onChange,
              physics: const ClampingScrollPhysics(),
              children: [
                Container(color: Colors.blue),
                Container(color: Colors.red),
                Container(color: Colors.green),
              ],
            ),
          ),
        ),
        Positioned.fill(
          bottom: 10,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3, // PageView has only 3 children
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300), // milliseconds instead of microseconds
                  width: currentSlide == index ? 15 : 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: currentSlide == index 
                      ? Colors.black 
                      : Colors.transparent,
                  border: Border.all(
                    color: Colors.black,
                )
              ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}