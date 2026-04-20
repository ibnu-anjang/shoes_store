import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/screens/cart/checkoutScreen.dart';

class AddToCart extends StatefulWidget {
  final Product product;
  final ProductSku selectedSku;
  final Color selectedColor;
  const AddToCart({
    super.key,
    required this.product,
    required this.selectedSku,
    required this.selectedColor,
  });

  @override
  State<AddToCart> createState() => _AddToCartState();
}

class _AddToCartState extends State<AddToCart> {
  int currentIndex = 1;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.black,
        ),
        child: Row(
          children: [
            // COUNTER
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (currentIndex != 1) {
                        setState(() {
                          currentIndex--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                  ),
                  Text(
                    currentIndex.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        currentIndex++;
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // BUTTONS
            Expanded(
              child: Row(
                children: [
                  // Add to Cart (Remote)
                  Expanded(
                    child: GestureDetector(
                      onTap: _isAdding ? null : () async {
                        setState(() => _isAdding = true);
                        try {
                           // Call without passing the empty list, since CartProvider handles it locally now
                           await provider.addToCartRemote(widget.selectedSku, currentIndex, color: widget.selectedColor);
                           if (!mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ditambahkan ke Keranjang!", style: TextStyle(fontWeight: FontWeight.bold)),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Gagal: $e", style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isAdding = false);
                        }
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: _isAdding 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              "Cart",
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Beli Sekarang (Direct to Checkout - Shopee Style)
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        // Create a buy now item with the correct SKU
                        final buyNowItem = CartItem(
                          product: widget.product,
                          sku: widget.selectedSku,
                          color: widget.selectedColor,
                          quantity: currentIndex,
                        );
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              items: [buyNowItem],
                              isBuyNow: true,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: kprimaryColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Beli Sekarang",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}