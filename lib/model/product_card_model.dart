import 'package:flutter/material.dart';

class ProductCardModel {
  final String image;
  final String title;
  final String description;
  final double price;
  final String unit; // e.g., "kg", "piece", "liter"
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  ProductCardModel({
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    required this.onTap,
    required this.onAddToCart,
  });
}