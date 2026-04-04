import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/reviewProvider.dart';

class Description extends StatefulWidget {
  final String productId; // Ditambahkan untuk filter review
  final String description;
  final String specification;
  final double initialRate; // Untuk perhitungan akumulasi

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
            ...localReviews.map((review) => Container(
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
                          Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${review.date.day}/${review.date.month}/${review.date.year}",
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
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
                    ],
                  ),
                )),
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
          child: SizedBox( // Menggunakan SizedBox untuk tinggi yang lebih fleksibel
            width: double.infinity,
            key: ValueKey(selectedIndex),
            child: content,
          ),
        ),
      ],
    );
  }
}