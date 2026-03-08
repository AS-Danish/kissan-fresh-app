import 'package:flutter/material.dart';

class ProductCardModel {
  final String? id; // Optional ID field for better tracking
  final String image;
  final List<String>? images;
  final String title;
  final String description;
  final double price;
  final String unit;
  final String? category; // Added category field
  final List<String>? tags; // Dynamic tags
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  final bool inStock; // Stock status

  ProductCardModel({
    this.id,
    required this.image,
    this.images,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    this.category,
    this.tags,
    this.inStock = true, // Default to true
    required this.onTap,
    required this.onAddToCart,
  });
}