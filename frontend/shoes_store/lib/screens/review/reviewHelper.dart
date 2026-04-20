import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/cartItem.dart';
import 'package:shoes_store/models/orderModel.dart';
import 'package:shoes_store/screens/review/reviewScreen.dart';
import '../../widgets/smartImage.dart';

/// Buka ReviewScreen untuk order tertentu.
/// - Jika hanya 1 item belum direview → langsung buka ReviewScreen.
/// - Jika >1 item belum direview → tampilkan bottom sheet pilih item.
void openReviewPicker(BuildContext context, Order order) {
  final unreviewedItems = order.items.where((i) => !i.isReviewed).toList();

  if (unreviewedItems.isEmpty) return;

  if (unreviewedItems.length == 1) {
    _pushReviewScreen(context, unreviewedItems.first, order.id);
    return;
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ReviewItemPickerSheet(
      unreviewedItems: unreviewedItems,
      orderId: order.id,
    ),
  );
}

void _pushReviewScreen(BuildContext context, CartItem item, String orderId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReviewScreen(item: item, orderId: orderId),
    ),
  );
}

class _ReviewItemPickerSheet extends StatelessWidget {
  final List<CartItem> unreviewedItems;
  final String orderId;

  const _ReviewItemPickerSheet({
    required this.unreviewedItems,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Produk untuk Direview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '${unreviewedItems.length} produk belum direview',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...unreviewedItems.map((item) => _buildItemTile(context, item)),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, CartItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(context);
        _pushReviewScreen(context, item, orderId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kcontentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SmartImage(
                url: item.displayImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Size ${item.selectedSize} • x${item.quantity}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
