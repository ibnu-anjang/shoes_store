import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';

class Description extends StatefulWidget {
  final String description;
  final String specification;
  final String review;

  const Description({
    super.key,
    required this.description,
    required this.specification,
    required this.review,
  });

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  int selectedIndex = 0;

  final TextEditingController reviewController = TextEditingController();
  final List<String> userReviews = [];

  @override
  Widget build(BuildContext context) {
    List<String> tabs = ["Description", "Specification", "Review"];

    Widget content;

    if (selectedIndex == 0) {
      content = Text(
        widget.description,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      );
    } else if (selectedIndex == 1) {
      content = Text(
        widget.specification,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      );
    } else {
      /// 🔥 REVIEW UI
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// LIST REVIEW
          ...userReviews.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text("• $e"),
              )),

          const SizedBox(height: 10),

          /// INPUT REVIEW
          TextField(
            controller: reviewController,
            decoration: InputDecoration(
              hintText: "Tulis review...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {
              if (reviewController.text.isNotEmpty) {
                setState(() {
                  userReviews.add(reviewController.text);
                  reviewController.clear();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
            ),
            child: const Text("Kirim Review"),
          ),
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
          child: Container(
            key: ValueKey(selectedIndex),
            child: content,
          ),
        ),
      ],
    );
  }
}