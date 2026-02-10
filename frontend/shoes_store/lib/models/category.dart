class Category {
  final String title;
  final String image;

  Category({
    required this.title, 
    required this.image
    });
}

final List<Category> categories = [
  Category(title: "shoes1", image: "assets/images/category/all.png"),
  Category(title: "shoes2", image: "assets/images/category/running.png"),
  Category(title: "shoes3", image: "assets/images/category/training.png"),
  Category(title: "shoes4", image: "assets/images/category/basketball.png"),
  Category(title: "shoes5", image: "assets/images/category/tennis.png"),
];