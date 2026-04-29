import 'package:flutter/material.dart';

class ProductCardModel {
  final String? id; // Optional ID field for better tracking
  final String image;
  final List<String>? images;
  final String title;
  final String description;
  final double price; // discount price
  final double? mrp; // original price
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
    this.mrp,
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
      'mrp': mrp,
      'unit': unit,
      'category': category,
      'tags': tags,
      'inStock': inStock,
      'stockCount': stockCount,
    };
  }

  factory ProductCardModel.fromJson(
    Map<String, dynamic> json, {
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
  }) {
    return ProductCardModel(
      id: json['id'],
      image: json['image'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      title: json['title'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      mrp: json['mrp'] != null ? (json['mrp']).toDouble() : null,
      unit: json['unit'] ?? 'unit',
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      inStock: json['inStock'] ?? true,
      stockCount: json['stockCount'] != null 
          ? (json['stockCount'] as num).toInt() 
          : (json['inStock'] == false ? 0 : 99),
      onTap: onTap ?? () {},
      onAddToCart: onAddToCart ?? () {},
    );
  }

  ProductCardModel copyWith({
    String? id,
    String? image,
    List<String>? images,
    String? title,
    String? description,
    double? price,
    double? mrp,
    String? unit,
    String? category,
    List<String>? tags,
    bool? inStock,
    int? stockCount,
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
  }) {
    return ProductCardModel(
      id: id ?? this.id,
      image: image ?? this.image,
      images: images ?? this.images,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
      onTap: onTap ?? this.onTap,
      onAddToCart: onAddToCart ?? this.onAddToCart,
    );
  }
}
