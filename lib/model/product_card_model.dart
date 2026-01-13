class ProductCardModel {
  final String productName;
  final String subtitle;
  final String price;
  final String? originalPrice;
  final String? imageUrl;
  final String? discountText;
  final bool isDeal;
  final Function() onTap;

  ProductCardModel({
    required this.productName,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.discountText,
    this.isDeal = false,
    required this.onTap,
  });
}