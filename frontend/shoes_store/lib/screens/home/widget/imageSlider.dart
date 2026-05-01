import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';
import '../../../widgets/smartImage.dart';

class ImageSlider extends StatefulWidget {
  final Function(int) onChange;
  final int currentSlide;
  final List<String> images;

  const ImageSlider({
    super.key,
    required this.onChange,
    required this.currentSlide,
    required this.images,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  
  final List<String> _fallbacks = [
    "assets/promo1.jpg",
    "assets/promo2.jpg",
    "assets/promo3.jpg",
  ];

  List<String> get _displayImages => widget.images.isNotEmpty ? widget.images : _fallbacks;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentSlide;
    _pageController = PageController(initialPage: _currentPage);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(ImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika images baru masuk, restart timer
    if (oldWidget.images.length != widget.images.length) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!mounted) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _displayImages.isEmpty) return;
      
      final nextPage = (_currentPage + 1) % _displayImages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onManualSwipe() {
    // Reset timer saat user geser manual supaya tidak tiba-tiba loncat
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Listener(
              onPointerDown: (_) => _autoScrollTimer?.cancel(),
              onPointerUp: (_) => _onManualSwipe(),
              child: PageView(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                allowImplicitScrolling: true,
                onPageChanged: (index) {
                  _currentPage = index;
                  widget.onChange(index);
                },
                physics: const BouncingScrollPhysics(),
                children: _displayImages.map((imagePath) {
                  return GestureDetector(
                    onTap: () => FullScreenViewer.show(context, imagePath),
                    child: SmartImage(
                      url: imagePath,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
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
                _displayImages.length, 
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.currentSlide == index ? 15 : 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.currentSlide == index
                        ? Colors.black
                        : Colors.transparent,
                    border: Border.all(color: Colors.black),
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