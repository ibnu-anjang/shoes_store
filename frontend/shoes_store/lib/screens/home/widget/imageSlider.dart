import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shoes_store/widgets/fullScreenViewer.dart';
import 'package:shoes_store/services/apiService.dart';
import '../../../widgets/smartImage.dart';

class ImageSlider extends StatefulWidget {
  final Function(int) onChange;
  final int currentSlide;

  const ImageSlider({
    super.key,
    required this.onChange,
    required this.currentSlide,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  List<String> sliderImages = [
    "assets/promo1.jpg",
    "assets/promo2.jpg",
    "assets/promo3.jpg",
  ];
  bool isLoading = true;
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchPromos();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || sliderImages.isEmpty) return;
      _currentPage = (_currentPage + 1) % sliderImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPromos() async {
    try {
      final promos = await ApiService.getPromos();
      if (promos.isNotEmpty) {
        setState(() {
          sliderImages = promos.map((p) => ApiService.normalizeImage(p['image_url'].toString())).toList();
        });
      }
    } catch (e) {
      debugPrint("Failed loading dynamic promos: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _startAutoScroll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                _currentPage = index;
                widget.onChange(index);
              },
              physics: const ClampingScrollPhysics(),
              children: sliderImages.map((imagePath) {
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
        Positioned.fill(
          bottom: 10,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                sliderImages.length, 
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