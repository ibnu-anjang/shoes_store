import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/provider/reviewProvider.dart';

class ItemDetails extends StatelessWidget {
  final Product product;
  final ProductSku? selectedSku;
  const ItemDetails({super.key, required this.product, this.selectedSku});

  @override
  Widget build(BuildContext context) {
    final reviewProvider = ReviewProvider.of(context);
    final localReviews = reviewProvider.getProductReviews(product.id.toString());
    final avgRating = reviewProvider.getAverageRating(product.id.toString(), product.rate);

    // Gunakan harga SKU jika terpilih, jika tidak gunakan harga base product
    final displayPrice = selectedSku != null ? selectedSku!.price : product.price;
    final displayStock = selectedSku != null ? selectedSku!.stockAvailable : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                product.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                ),
              ),
            ),
            if (selectedSku != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: displayStock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  displayStock > 0 ? "Stok: $displayStock" : "Habis",
                  style: TextStyle(
                    color: displayStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatRupiah(displayPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                // rating
                Row(
                  children: [
                    Container(
                      width: 55,
                      height: 25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: kprimaryColor,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "(${localReviews.length} ulasan)",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    )
                  ],
                )
              ],
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: "kategori: ",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: product.type,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ]
              )
            )
          ],
        ),
      ],
    );
  }
}