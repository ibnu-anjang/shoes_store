import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/models/category.dart' as model;
import 'package:shoes_store/screens/home/widget/imageSlider.dart';
import 'package:shoes_store/screens/home/widget/productCart.dart';
import 'package:shoes_store/screens/home/widget/searchBar.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/screens/chatbot/chatBotScreen.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/services/productService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentSlider = 0;
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  bool isLoading = true;
  String selectedCategory = "All";
  String searchQuery = "";
  List<model.Category> dynamicCategories = [model.Category(title: "All", image: "")];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final results = await ProductService.getProducts();
    debugPrint("DEBUG: Loaded ${results.length} products");
    if (mounted) {
      setState(() {
        allProducts = results;
        displayedProducts = results;
        final categoriesSet = results.map((p) => p.category).toSet();
        dynamicCategories = [model.Category(title: "All", image: "")] 
          ..addAll(categoriesSet.map((c) => model.Category(title: c, image: "")));
        isLoading = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      displayedProducts = allProducts.where((product) {
        final matchesCategory = selectedCategory == "All" || 
                                product.category.trim().toLowerCase() == selectedCategory.trim().toLowerCase();
        final matchesSearch = product.title.trim().toLowerCase().contains(searchQuery.trim().toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
    debugPrint("DEBUG: Filtered to ${displayedProducts.length} products (Category: $selectedCategory, Search: $searchQuery)");
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context).userName;

    return Scaffold(
      backgroundColor: kcontentColor,
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: kprimaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient App Bar / Header ──────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kprimaryColor, Color(0xFFFF8C42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + greeting + AI button dalam satu baris
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: kprimaryColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Shoes Store",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                              ),
                              Text(
                                '${_getGreeting()}, $userName 👋',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderBtn(
                          Icons.smart_toy_outlined,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantChatScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Search bar di dalam header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: MySearchBar(
                        onFilterTap: null,
                        onChanged: (value) {
                          searchQuery = value;
                          _filterProducts();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // Offline Banner
                  if (!isLoading && ProductService.isOfflineData)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_off, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Mode Offline: Menampilkan data simpanan",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Categories
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dynamicCategories.length,
                      itemBuilder: (context, index) {
                        final category = dynamicCategories[index];
                        final isSelected = selectedCategory == category.title;
                        return GestureDetector(
                          onTap: () => setState(() {
                            selectedCategory = category.title;
                            _filterProducts();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? kprimaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: kprimaryColor.withAlpha(77), blurRadius: 8, offset: const Offset(0, 3))]
                                  : [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category.title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Promo Slider
                  ImageSlider(
                    currentSlide: currentSlider,
                    onChange: (value) => setState(() => currentSlider = value),
                  ),

                  const SizedBox(height: 20),

                  // Section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Special for You",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "${displayedProducts.length} produk",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Product Grid
                  isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(color: kprimaryColor),
                          ),
                        )
                      : (displayedProducts.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: displayedProducts.length,
                              itemBuilder: (context, index) =>
                                  ProductCard(product: displayedProducts[index]),
                            )),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "Produk tidak ditemukan",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
