import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/screens/order/orderListScreen.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "assets/pp.png",
            fit: BoxFit.cover,
            height: size.height,
            width: size.width,
            errorBuilder: (context, error, stackTrace) => Container(
              height: size.height,
              width: size.width,
              color: kcontentColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 50), 
            child: Align(
              alignment: Alignment.topCenter, 
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity, 
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  children: [
                                    const CircleAvatar(
                                      radius: 42,
                                      backgroundImage: AssetImage("assets/pp.png"),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        height: 25,
                                        width: 25,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.fromARGB(255, 95, 225, 99),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildButton("ADD FRIEND", Colors.transparent, Colors.black),
                                    const SizedBox(width: 8),
                                    _buildButton("Follow", Colors.pink, Colors.white),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "shoes store",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 35),
                            ),
                            const Text(
                              "shoes distributor",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black45),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Toko sepatu terlengkap dan terpercaya",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20), 
                      const Divider(color: Colors.black12),
                      SizedBox(
                        height: 65,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            friendAndMore("FRIENDS", "2318"),
                            friendAndMore("FOLLOWING", "364"),
                            friendAndMore("FOLLOWER", "175"),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 10),
                      // Tombol Pesanan Saya
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrderListScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                            label: const Text(
                              "Pesanan Saya",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kprimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildButton(String label, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bgColor,
        border: bgColor == Colors.transparent ? Border.all(color: Colors.black54) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor,
        ),
      ),
    );
  }
  
  SizedBox friendAndMore(title, number) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black26),
          ),
          Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black),
          )
        ],
      ),
    );
  }
}