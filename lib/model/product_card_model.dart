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
  final int stockCount; // Exact stock quantity


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
    this.inStock = true,
    this.stockCount = 0,
    required this.onTap,
    required this.onAddToCart,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'images': images,
      'title': title,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'tags': tags,
      'inStock': inStock,
      'stockCount': stockCount,
    };

  }

  factory ProductCardModel.fromJson(Map<String, dynamic> json, {VoidCallback? onTap, VoidCallback? onAddToCart}) {
    return ProductCardModel(
      id: json['id'],
      image: json['image'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      title: json['title'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'unit',
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      inStock: json['inStock'] ?? true,
      stockCount: (json['stockCount'] ?? 0).toInt(),
      onTap: onTap ?? () {},
      onAddToCart: onAddToCart ?? () {},
    );

  }
}