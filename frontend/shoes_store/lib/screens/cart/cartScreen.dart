import 'package:flutter/material.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/productModel.dart';
import '../../widgets/smartImage.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import 'package:shoes_store/screens/cart/checkoutScreen.dart';
import 'package:shoes_store/provider/cartProvider.dart';
import 'package:shoes_store/constant.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = CartProvider.of(context, listen: false);
    if (mounted) {
      await provider.fetchCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    final cartItems = provider.cart;
    final bool allSelected =
        cartItems.isNotEmpty && cartItems.every((item) => item.isSelected);

    return Scaffold(
      backgroundColor: kcontentColor,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(context),

            // SELECT ALL HEADER
            if (cartItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: kprimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
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
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: kprimaryColor,
                child: cartItems.isEmpty
                  ? (provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
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
                          ))
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 20,
                        left: 15,
                        right: 15,
                      ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) =>
                                      provider.toggleSelection(index),
                                ),

                                // Product image (clickable)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailScreen(
                                          product: cartItem.product,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SmartImage(
                                      url: cartItem.displayImage,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.product.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Mode normal: tampil size biasa
                                      // Mode edit: tampil dropdown ganti ukuran
                                      if (!_isEditing)
                                        Row(
                                          children: [
                                            Text(
                                              cartItem.selectedSize,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text("|", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: cartItem.selectedColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        _buildSizeDropdown(context, index, cartItem, provider),

                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatRupiah(cartItem.totalPrice),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: kprimaryColor,
                                            ),
                                          ),
                                          // Quantity controls
                                          Row(
                                            children: [
                                              _buildQtyButton(
                                                Icons.remove,
                                                provider.isLoading ? null : () => provider.decrementQtn(index),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: provider.isLoading
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: kprimaryColor,
                                                        ),
                                                      )
                                                    : Text(
                                                        '${cartItem.quantity}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                              _buildQtyButton(
                                                Icons.add,
                                                provider.isLoading ? null : () => _incrementQty(index),
                                              ),
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
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Total Pembayaran",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                formatRupiah(provider.totalPrice()),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kprimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.selectedCount == 0
                  ? null
                  : () {
                      final selectedItems = provider.cart
                          .where((item) => item.isSelected)
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            items: selectedItems,
                            isBuyNow: false,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                "Checkout (${provider.selectedCount})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSku(int index, ProductSku newSku) async {
    final provider = CartProvider.of(context, listen: false);
    final cartItem = provider.cart[index];
    if (cartItem.id == null || newSku.id == cartItem.sku.id) return;
    try {
      // Hapus item lama, tambah item baru dengan SKU berbeda
      await provider.removeAt(index);
      await provider.addToCartRemote(newSku, cartItem.quantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildSizeDropdown(BuildContext context, int index, CartItem cartItem, CartProvider provider) {
    final skus = cartItem.product.skus;
    if (skus.isEmpty) {
      return Text(
        cartItem.selectedSize,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      );
    }
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kcontentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kprimaryColor.withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductSku>(
          value: skus.any((s) => s.id == cartItem.sku.id) ? cartItem.sku : skus.first,
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.expand_more, size: 14, color: kprimaryColor),
          items: skus.map((sku) {
            return DropdownMenuItem<ProductSku>(
              value: sku,
              child: Text(
                '${sku.variantName}${sku.stockAvailable == 0 ? " (Habis)" : ""}',
                style: TextStyle(
                  fontSize: 11,
                  color: sku.stockAvailable == 0 ? Colors.grey : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (newSku) {
            if (newSku != null && newSku.stockAvailable > 0) {
              _changeSku(index, newSku);
            }
          },
        ),
      ),
    );
  }

  void _incrementQty(int index) {
    final provider = CartProvider.of(context, listen: false);
    provider.incrementQtn(index).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  Widget _buildQtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kcontentColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey.shade400 : Colors.black),
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
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios),
                )
              : const SizedBox(width: 48),
          const Text(
            "My Cart",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(
              _isEditing ? "Done" : "Edit",
              style: const TextStyle(
                color: kprimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
