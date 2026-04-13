import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/reviewProvider.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/provider/orderProvider.dart';
import 'package:shoes_store/screens/review/reviewScreen.dart';
import 'package:shoes_store/services/apiService.dart';
import '../../../widgets/smartImage.dart';

class Description extends StatefulWidget {
  final String productId;
  final String description;
  final String specification;
  final double initialRate;

  const Description({
    super.key,
    required this.productId,
    required this.description,
    required this.specification,
    required this.initialRate,
  });

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final reviewProvider = ReviewProvider.of(context);
    final userProvider = UserProvider.of(context);
    final orderProvider = OrderProvider.of(context);

    final localReviews = reviewProvider.getProductReviews(widget.productId);
    final avgRating = reviewProvider.getAverageRating(widget.productId, widget.initialRate);

    List<String> tabs = ["Description", "Specification", "Review"];

    Widget content;

    if (selectedIndex == 0) {
      content = Text(
        widget.description,
        style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
      );
    } else if (selectedIndex == 1) {
      content = Text(
        widget.specification,
        style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
      );
    } else {
      /// 🔥 REAL REVIEW UI
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                "${avgRating.toStringAsFixed(1)} / 5.0",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                "(${5 + localReviews.length} Reviews)",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (localReviews.isEmpty)
             const Center(
               child: Padding(
                 padding: EdgeInsets.symmetric(vertical: 20),
                 child: Text("Belum ada review tambahan dari pembeli.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               ),
             )
          else
            ...localReviews.map((review) {
              final isOwnReview = review.userId == userProvider.userId;
              
              return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kcontentColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isOwnReview)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kprimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text("Anda", style: TextStyle(color: kprimaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "${review.date.day}/${review.date.month}/${review.date.year}",
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              if (isOwnReview) ...[
                                const SizedBox(width: 12),
                                // EDIT BUTTON
                                GestureDetector(
                                  onTap: () {
                                    // Cari order yang sesuai produk ini
                                    try {
                                      final order = orderProvider.orders.firstWhere(
                                        (o) => o.items.any((item) => item.product.id.toString() == widget.productId)
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewScreen(
                                            order: order,
                                            existingReview: review,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Data pesanan tidak ditemukan")),
                                      );
                                    }
                                  },
                                  child: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                // DELETE BUTTON
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text("Hapus Ulasan"),
                                        content: const Text("Apakah Anda yakin ingin menghapus ulasan ini?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                                          TextButton(
                                            onPressed: () {
                                              reviewProvider.deleteReview(widget.productId, review.id);
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Ulasan berhasil dihapus")),
                                              );
                                            },
                                            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          Icons.star, 
                          size: 14, 
                          color: index < review.rating ? Colors.amber : Colors.grey.shade300
                        )),
                      ),
                      const SizedBox(height: 8),
                      Text(review.comment, style: const TextStyle(fontSize: 13)),
                      if (review.imagePath != null) ...[
                        const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog.fullscreen(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: SmartImage(
                                        url: ApiService.normalizeImage(review.imagePath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SmartImage(
                            url: ApiService.normalizeImage(review.imagePath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                );
            }).toList(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 TAB + SLIDING BACKGROUND
        LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth / 3;

            return Stack(
              children: [
                /// BACKGROUND ORANGE (GESER)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: selectedIndex * width,
                  child: Container(
                    width: width,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kprimaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                /// TAB TEXT
                Row(
                  children: List.generate(tabs.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text(tabs[index]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        /// 🔥 CONTENT (ANIMASI)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: double.infinity,
            key: ValueKey(selectedIndex),
            child: content,
          ),
        ),
      ],
    );
  }
}