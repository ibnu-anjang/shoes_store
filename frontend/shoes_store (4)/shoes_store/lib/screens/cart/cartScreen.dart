import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/screens/cart/checkOut.dart';
import 'package:shoes_store/screens/navBar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    final finalList = provider.cart;
    // quantity
    productQuantity(IconData icon, int index) {
      return GestureDetector( onTap: () {
        setState(() {
          icon == Icons.add 
          ? provider.incrementQtn(index)
          : provider.decrementQtn(index);
        });
      },
      child: Icon(icon,size: 20,),
      );
    }
    return Scaffold(
      // total sama co
      bottomSheet: CheckOut(),
      backgroundColor: kcontentColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios)
              ),
              const Text(
                "My Cart",style: 
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
              ),
              ),
              Container(),
              ],
            ),
            ), 
            Expanded(child: ListView.builder(
              itemCount:finalList.length,
              itemBuilder: (context, index){
                final cartItem = finalList[index];
              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            height: 120,
                            width: 100,
                            decoration: BoxDecoration(
                              color: kcontentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(cartItem.image),
                          ),
                          const SizedBox(width: 10,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItem.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5,),
                              Text(
                                cartItem.category,
                                style:const  TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8,),
                              Text(
                                "\$${cartItem.price}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    ),
                    Positioned(
                      top: 35,
                      right: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(onPressed: () {
                            finalList.removeAt(index);
                            setState(() {
                              
                            });
                          }, 
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 25,
                          ),
                          ),
                          const SizedBox(height: 10,),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: kcontentColor,
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10,),
                                  productQuantity(Icons.add, index),
                                  const SizedBox(width: 10,),
                                  Text(
                                    cartItem.quantity.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  productQuantity(Icons.remove, index),
                                  const SizedBox(width: 10,),
                                ],
                              ),
                            ),
                        ],
                    ),
                    ),
                ],
              );
            },
            ),
            ),
          ],
      ),
      ),
    );
  }
}