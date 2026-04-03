import 'package:flutter/material.dart';
import '../../provider/cartProvider.dart';
import '../../constant.dart';
import 'checkOut.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    final finalist = provider.cart;

    return Scaffold(
      backgroundColor: kcontentColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                buildHeader(context),
                Expanded(
                  child: finalist.isEmpty 
                    ? const Center(child: Text("Keranjang Kosong"))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 250, left: 15, right: 15),
                        itemCount: finalist.length,
                        itemBuilder: (context, index) {
                          final cartItem = finalist[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Image.asset(cartItem.image, width: 50),
                              title: Text(cartItem.title),
                              subtitle: Text("\$${cartItem.price}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => finalist.removeAt(index)),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          const CheckOut(), 
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}