import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/provider/cartProvider.dart';

class AddToCart extends StatefulWidget {
  final Product product;
  const AddToCart({super.key, required this.product});

  @override
  State<AddToCart> createState() => _AddToCartState();
}

class _AddToCartState extends State<AddToCart> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        // MENGHAPUS height: 85 agar fleksibel
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.black,
        ),
        child: Row(
          children: [
            // BAGIAN KIRI: Counter
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Agar Row counter tidak serakah tempat
                children: [
                  IconButton(
                    constraints: const BoxConstraints(), // Menghilangkan padding bawaan iconbutton
                    onPressed: () {
                      if (currentIndex != 1) {
                        setState(() {
                          currentIndex--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentIndex.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
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

            const SizedBox(width: 10), // Jarak antar widget

            // BAGIAN KANAN: Tombol Add to Cart
            Expanded( 
              child: GestureDetector(
                onTap: () {
                  provider.toggleFavorite(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Successfully added", style: TextStyle(fontWeight: FontWeight.bold)),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  height: 50, // Tinggi tombol diperkecil sedikit agar pas
                  decoration: BoxDecoration(
                    color: kprimaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Font diperkecil sedikit untuk layar sempit
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}