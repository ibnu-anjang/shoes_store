import 'package:flutter/material.dart';
import '../../provider/cartProvider.dart';
import '../../constant.dart';
import '../navBar.dart';

class CheckOut extends StatefulWidget {
  const CheckOut({super.key});

  @override
  State<CheckOut> createState() => _CheckOutState();
}
class _CheckOutState extends State<CheckOut> {
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController waController = TextEditingController();
  String paymentMethod = "Cash on Delivery";
  String ewallet = "Dana";
  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ListView( 
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("\$${provider.totalPrice()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kprimaryColor)),
                ],
              ),
              const Divider(height: 30),
              const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: alamatController,
                decoration: InputDecoration(
                  hintText: "Masukkan alamat lengkap",
                  filled: true, fillColor: kcontentColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Nomor WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: waController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Contoh: 0812345678",
                  prefixIcon: const Icon(Icons.phone),
                  filled: true, fillColor: kcontentColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                items: const [
                  DropdownMenuItem(value: "Cash on Delivery", child: Text("Cash on Delivery (COD)")),
                  DropdownMenuItem(value: "E-Wallet", child: Text("E-Wallet")),
                ],
                onChanged: (val) => setState(() => paymentMethod = val!),
                decoration: InputDecoration(filled: true, fillColor: kcontentColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (provider.cart.isEmpty) {
                    _showSnackBar(context, "Keranjang Anda masih kosong!", Colors.orange);
                    return;
                  }
                  if (alamatController.text.isEmpty || waController.text.isEmpty) {
                    _showSnackBar(context, "Tolong isi alamat dan nomor WhatsApp!", Colors.red);
                    return;
                  }
                  _showSnackBar(context, "Pembayaran Berhasil! Pesanan diproses.", Colors.green);
                  provider.cart.clear(); 
                  provider.notifyListeners(); 
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const BottomNavBar()), 
                      (route) => false,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Konfirmasi Pesanan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: warna, duration: const Duration(seconds: 2)),
    );
  }
}