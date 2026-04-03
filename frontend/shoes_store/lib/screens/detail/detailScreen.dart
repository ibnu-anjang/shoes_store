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
  List<String> sizes = ["38", "39", "40", "41", "42"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      floatingActionButton: AddToCart(product: widget.product),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
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
                          ItemDetails(product: widget.product),
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
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: currentColor == index
                                        ? Colors.white
                                        : widget.product.colors[index],
                                    border: currentColor == index
                                        ? Border.all(
                                            color: widget.product.colors[index],
                                          )
                                        : null,
                                  ),
                                  padding: currentColor == index
                                      ? const EdgeInsets.all(2)
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.product.colors[index],
                                      shape: BoxShape.circle,
                                    ),
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
                              sizes.length,
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
                                    sizes[index],
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
                            description: widget.product.description,
                            specification: widget.product.specification,
                            review: widget.product.review,
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