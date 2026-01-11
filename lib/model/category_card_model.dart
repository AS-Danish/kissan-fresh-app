import 'package:flutter/cupertino.dart';

class CategoryCardModel {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  CategoryCardModel({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
