import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/screens/home/widget/imageSlider.dart';
import 'package:shoes_store/screens/home/widget/productCart.dart';
import 'package:shoes_store/screens/home/widget/searchBar.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/screens/chatbot/chatBotScreen.dart';
import 'package:shoes_store/provider/userProvider.dart';
import 'package:shoes_store/services/productService.dart';
import 'package:shoes_store/services/apiService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentSlider = 0;
  List<Product> displayedProducts = [];
  List<String> bannerImages = [];
  List<String> categories = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String selectedCategory = "All";
  String searchQuery = "";
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProducts = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => isLoading = true);

    final results = await Future.wait([
      ProductService.searchProducts(page: 1, limit: 20),
      ProductService.getCategories(),
      _fetchBanners(),
    ]);

    if (mounted) {
      final searchResult = results[0] as Map<String, dynamic>;
      final cats = results[1] as List<String>;
      final banners = results[2] as List<String>;
      setState(() {
        displayedProducts = searchResult['items'] as List<Product>;
        _totalProducts = searchResult['total'] as int;
        _totalPages = searchResult['pages'] as int;
        _currentPage = 1;
        categories = cats;
        bannerImages = banners;
        isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchBanners() async {
    try {
      final promos = await ApiService.getPromos();
      if (promos.isNotEmpty) {
        return promos.map((p) => ApiService.normalizeImage(p['image_url'].toString())).toList();
      }
    } catch (e) {
      debugPrint("Error loading promos: $e");
    }
    return [];
  }

  Future<void> _search({bool reset = true}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        _currentPage = 1;
      });
    } else {
      setState(() => isLoadingMore = true);
    }

    final result = await ProductService.searchProducts(
      q: searchQuery.isEmpty ? null : searchQuery,
      category: selectedCategory == "All" ? null : selectedCategory,
      page: _currentPage,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        if (reset) {
          displayedProducts = result['items'] as List<Product>;
        } else {
          displayedProducts.addAll(result['items'] as List<Product>);
        }
        _totalProducts = result['total'] as int;
        _totalPages = result['pages'] as int;
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchQuery = value;
      _search();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => selectedCategory = category);
    _search();
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _totalPages || isLoadingMore) return;
    _currentPage++;
    await _search(reset: false);
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
        onRefresh: _loadInitial,
        color: kprimaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                    Row(
                      children: [
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                          ),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: MySearchBar(
                        onFilterTap: null,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // Category chips
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip("All"),
                          ...categories.map(_buildCategoryChip),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  ImageSlider(
                    images: bannerImages,
                    currentSlide: currentSlider,
                    onChange: (value) => setState(() => currentSlider = value),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Special for You",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "$_totalProducts produk",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(color: kprimaryColor),
                          ),
                        )
                      : displayedProducts.isEmpty
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
                              itemBuilder: (context, index) => ProductCard(product: displayedProducts[index]),
                            ),

                  // Load More
                  if (!isLoading && _currentPage < _totalPages)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: isLoadingMore
                            ? const CircularProgressIndicator(color: kprimaryColor)
                            : TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more, color: kprimaryColor),
                                label: Text(
                                  "Muat lebih banyak (${_totalProducts - displayedProducts.length} lagi)",
                                  style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = selectedCategory == title;
    return GestureDetector(
      onTap: () => _onCategoryChanged(title),
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
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
