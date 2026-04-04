import 'package:flutter/material.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/models/category.dart' as model;
import 'package:shoes_store/screens/home/widget/imageSlider.dart';
import 'package:shoes_store/screens/home/widget/productCart.dart';
import 'package:shoes_store/screens/home/widget/searchBar.dart';
import 'package:shoes_store/constant.dart';


import 'package:shoes_store/services/product_service.dart';

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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Kategori",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: model.categories.map((category) {
                  final isSelected = selectedCategory == category.title;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category.title;
                        _filterProducts();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? kprimaryColor : kcontentColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? kprimaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        category.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // search bar
              MySearchBar(
                onFilterTap: _showFilterOptions,
                onChanged: (value) {
                  searchQuery = value;
                  _filterProducts();
                },
              ),
              
              // Offline Indicator Banner
              if (!isLoading && ProductService.isOfflineData)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        "Mode Offline: Menampilkan data simpanan",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              
              // Categories Section
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: model.categories.length,
                  itemBuilder: (context, index) {
                    final category = model.categories[index];
                    final isSelected = selectedCategory == category.title;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category.title;
                          _filterProducts();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? kprimaryColor : kcontentColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: kprimaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              ImageSlider(
                currentSlide: currentSlider,
                onChange: (value) {
                  setState(() {
                    currentSlider = value;
                  });
                },
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Special for You",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Optimized Grid
              isLoading 
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ))
                : (displayedProducts.isEmpty 
                    ? _buildEmptyState()
                    : GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: displayedProducts.map((product) => ProductCard(product: product)).toList(),
                      )),
            ],
          ),
        ),
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
