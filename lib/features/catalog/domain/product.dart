class Product {
  final String id;
  final String image;
  final String title;
  final String description;
  final double price;
  final String unit;
  final String category;
  final List<String>? images;

  const Product({
    required this.id,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    this.images,
  });
}
