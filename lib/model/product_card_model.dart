import 'package:flutter/material.dart';

class ProductCardModel {
  final String? id; // Optional ID field for better tracking
  final String image;
  final String title;
  final String description;
  final double price;
  final String unit;
  final String? category; // Added category field
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  ProductCardModel({
    this.id,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    this.category,
    required this.onTap,
    required this.onAddToCart,
  });
}