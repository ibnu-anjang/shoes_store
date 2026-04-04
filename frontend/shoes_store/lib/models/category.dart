class Category {
  final String title;
  final String image;

  Category({
    required this.title, 
    required this.image
    });
}

final List<Category> categories = [
  Category(title: "All", image: "assets/promo1.jpg"),
  Category(title: "Sneakers", image: "assets/arkakhakisneak.jpg"),
  Category(title: "Running Shoes", image: "assets/adiduramorun.jpg"),
  Category(title: "formal shoes", image: "assets/marelliform.webp"),
  Category(title: "flat shoes", image: "assets/heavesflat.webp"),
  Category(title: "loafers shoes", image: "assets/wirkenloafer.jpg"),
  Category(title: "slip-on shoes", image: "assets/vansclassicslip.jpg"),
];