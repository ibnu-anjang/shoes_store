import 'package:flutter/material.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import 'package:shoes_store/screens/cart/checkoutScreen.dart';
import '../../provider/cartProvider.dart';
import '../../constant.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    final cartItems = provider.cart;
    final bool allSelected = cartItems.isNotEmpty && cartItems.every((item) => item.isSelected);

    return Scaffold(
      backgroundColor: kcontentColor,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(context),
            
            // SELECT ALL HEADER
            if (cartItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: kprimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => provider.selectAll(val ?? false),
                    ),
                    Text(
                      "Pilih Semua (${cartItems.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // LIST ITEMS
            Expanded(
              child: cartItems.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        Text(
                          "Keranjang Kosong",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // CHECKBOX
                              Checkbox(
                                value: cartItem.isSelected,
                                activeColor: kprimaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => provider.toggleSelection(index),
                              ),

                              // Product image (clickable)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(product: cartItem.product),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    cartItem.product.image,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.product.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    // Size/Color display or edit
                                    if (_isEditing) 
                                      _buildEditOptions(context, provider, index, cartItem)
                                    else
                                      Text(
                                        "Size ${cartItem.selectedSize} | Color",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                    
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "\$${cartItem.totalPrice.toStringAsFixed(1)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kprimaryColor),
                                        ),
                                        // Quantity controls
                                        Row(
                                          children: [
                                            _buildQtyButton(Icons.remove, () => provider.decrementQtn(index)),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            _buildQtyButton(Icons.add, () => provider.incrementQtn(index)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Delete Button
                              if (_isEditing)
                                IconButton(
                                  onPressed: () => provider.removeAt(index),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),

            // CHECKOUT FOOTER
            if (cartItems.isNotEmpty) _buildCheckoutFooter(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutFooter(BuildContext context, CartProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Total Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                "\$${provider.totalPrice().toStringAsFixed(1)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kprimaryColor),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.selectedCount == 0 
                ? null 
                : () {
                    final selectedItems = provider.cart.where((item) => item.isSelected).toList();
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(items: selectedItems, isBuyNow: false)
                      )
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(
                "Checkout (${provider.selectedCount})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOptions(BuildContext context, CartProvider provider, int index, var cartItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cartItem.product.sizes.map<Widget>((size) {
              bool isSelected = cartItem.selectedSize == size;
              return GestureDetector(
                onTap: () => provider.updateItem(index, size, cartItem.selectedColor),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? kprimaryColor : kcontentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(size, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kcontentColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: Colors.black),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Navigator.canPop(context) 
            ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios))
            : const SizedBox(width: 48), 
          const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? "Done" : "Edit", style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}