import 'dart:ui';

class TrendingItemModel {
  final String productName;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final VoidCallback onTap;

  TrendingItemModel({
    required this.productName,
    required this.subtitle,
    required this.price,
    this.imageUrl,
    required this.onTap,
  });
}