import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/screens/detail/widget/addToCart.dart';
import 'package:shoes_store/screens/detail/widget/description.dart';
import 'package:shoes_store/screens/detail/widget/detailAppBar.dart';
import 'package:shoes_store/screens/detail/widget/imageSlider.dart';
import 'package:shoes_store/screens/detail/widget/itemDetails.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int currentImage = 0;
  int currentColor = 1;
  int currentSize = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      floatingActionButton: widget.product.skus.isNotEmpty 
        ? AddToCart(
            product: widget.product,
            selectedSku: widget.product.skus[currentSize],
            selectedColor: widget.product.colors.isNotEmpty
                ? widget.product.colors[currentColor < widget.product.colors.length ? currentColor : 0]
                : Colors.black,
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Column(
          children: [
            DetailAppBar(product: widget.product),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    MyImageSlider(
                      image: widget.product.image,
                      onChange: (index) {
                        setState(() {
                          currentImage = index;
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    // Hanya tampilkan dots jika ada lebih dari 1 gambar (dinamis)
                    if (1 > 1) 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        1,
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
                            product: widget.product,
                            selectedSku: widget.product.skus.isNotEmpty
                                ? widget.product.skus[currentSize]
                                : null,
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
                              widget.product.colors.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentColor = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 15),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.product.colors[index],
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
                            children: List.generate(
                              widget.product.skus.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentSize = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: currentSize == index
                                        ? kprimaryColor
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: currentSize == index
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
                                    widget.product.skus[index].variantName,
                                    style: TextStyle(
                                      color: currentSize == index
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
                             productId: widget.product.id.toString(),
                             description: widget.product.description,
                             specification: widget.product.specification,
                             initialRate: widget.product.rate,
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