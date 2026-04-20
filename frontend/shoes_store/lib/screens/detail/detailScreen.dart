import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/screens/detail/widget/addToCart.dart';
import 'package:shoes_store/screens/detail/widget/description.dart';
import 'package:shoes_store/screens/detail/widget/detailAppBar.dart';
import 'package:shoes_store/screens/detail/widget/imageSlider.dart';
import 'package:shoes_store/screens/detail/widget/itemDetails.dart';
import 'package:shoes_store/services/productService.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int currentImage = 0;
  int currentColor = 0;
  int? currentSizeIndex; // null means no selection yet
  late Product _currentProduct;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  late List<String> currentGallery;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika produk berubah (misal refresh), bangun ulang gallery
    if (oldWidget.product.id != widget.product.id) {
       _currentProduct = widget.product;
       _rebuildGallery();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _rebuildGallery();
    _checkAndFetchFullProduct();
  }

  void _rebuildGallery([Color? selectedColor]) {
    final c = selectedColor ?? (_currentProduct.colors.isNotEmpty ? _currentProduct.colors[currentColor] : null);
    
    List<String> newGallery = [];
    
    if (c != null && _currentProduct.colorGalleries.containsKey(c)) {
      newGallery.addAll(_currentProduct.colorGalleries[c]!);
    }
    
    newGallery.addAll(_currentProduct.generalGallery);
    
    if (newGallery.isEmpty) {
      newGallery = List.from(_currentProduct.gallery); 
    }
    
    currentGallery = newGallery;
    currentImage = 0;
    if (_pageController.hasClients) {
       _pageController.jumpToPage(0);
    }
  }

  Future<void> _checkAndFetchFullProduct() async {
    if (_currentProduct.colors.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final products = await ProductService.getProducts();
        final realProduct = products.firstWhere(
            (p) => p.id == _currentProduct.id,
            orElse: () => _currentProduct);
        if (mounted) {
          setState(() {
            _currentProduct = realProduct;
            _rebuildGallery();
          });
        }
      } catch (e) {
        debugPrint("Error fetching full product: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  List<ProductSku> get filteredSkus {
    if (_currentProduct.colors.isEmpty) return _currentProduct.skus;
    final selectedColorHex = colorToHex(_currentProduct.colors[currentColor]);
    return _currentProduct.skus.where((sku) {
      return sku.colorHex == null || sku.colorHex == selectedColorHex;
    }).toList();
  }

  ProductSku? get selectedSku {
    final list = filteredSkus;
    if (currentSizeIndex != null && currentSizeIndex! < list.length) {
      return list[currentSizeIndex!];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kcontentColor,
        body: Center(child: CircularProgressIndicator(color: kprimaryColor)),
      );
    }
    return Scaffold(
      backgroundColor: kcontentColor,
      floatingActionButton: selectedSku != null 
        ? AddToCart(
            product: _currentProduct,
            selectedSku: selectedSku!,
            selectedColor: _currentProduct.colors.isNotEmpty
                ? _currentProduct.colors[currentColor]
                : Colors.black,
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Column(
          children: [
            DetailAppBar(product: _currentProduct),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    MyImageSlider(
                      controller: _pageController,
                      images: currentGallery,
                      onChange: (index) {
                        setState(() {
                          currentImage = index;
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    // Dots (Hanya tampilkan jika lebih dari 1 gambar)
                    if (currentGallery.length > 1) 
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          currentGallery.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: currentImage == index ? 15 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: currentImage == index
                                  ? Colors.black
                                  : Colors.transparent,
                              border: Border.all(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(40),
                          topLeft: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ItemDetails(
                            product: _currentProduct,
                            selectedSku: selectedSku,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Color",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: List.generate(
                              _currentProduct.colors.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentColor = index;
                                    currentSizeIndex = null; // Reset size selection on color change
                                    _rebuildGallery(_currentProduct.colors[index]);
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 15),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentProduct.colors[index],
                                    border: currentColor == index
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 3,
                                          )
                                        : Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                    boxShadow: currentColor == index 
                                      ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                      : [],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),
                          const Text(
                            "Size",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              filteredSkus.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentSizeIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: currentSizeIndex == index
                                        ? kprimaryColor
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: currentSizeIndex == index
                                        ? [
                                            BoxShadow(
                                              color: kprimaryColor.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    filteredSkus[index].variantName,
                                    style: TextStyle(
                                      color: currentSizeIndex == index
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                           Description(
                             productId: _currentProduct.id.toString(),
                             description: _currentProduct.description,
                             specification: _currentProduct.specification,
                             initialRate: _currentProduct.rate,
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}