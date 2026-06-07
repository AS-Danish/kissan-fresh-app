import 'package:flutter/material.dart';

class ProductVariation {
  final String? id;
  final String unit;
  final String unitValue;
  final double price;
  final double? mrp;
  final double? discountPercentage;
  final String? image;
  final bool inStock;
  final int stockCount;

  ProductVariation({
    this.id,
    required this.unit,
    required this.unitValue,
    required this.price,
    this.mrp,
    this.discountPercentage,
    this.image,
    this.inStock = true,
    this.stockCount = 0,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id']?.toString(),
      unit: json['unit']?.toString() ?? '',
      unitValue: json['unitValue']?.toString() ?? '1',
      price: (json['price'] ?? 0).toDouble(),
      mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
      discountPercentage: json['discountPercentage'] != null ? (json['discountPercentage'] as num).toDouble() : null,
      image: json['image']?.toString(),
      inStock: json['inStock'] ?? true,
      stockCount: json['stockCount'] != null ? (json['stockCount'] as num).toInt() : (json['inStock'] == false ? 0 : 99),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit': unit,
      'unitValue': unitValue,
      'price': price,
      'mrp': mrp,
      'discountPercentage': discountPercentage,
      'image': image,
      'inStock': inStock,
      'stockCount': stockCount,
    };
  }
}

class ProductCardModel {
  final String? id; // Optional ID field for better tracking
  final String image;
  final List<String>? images;
  final String title;
  final String description;
  final double price; // discount price
  final double? mrp; // original price
  final String unit;
  final String? quantity;
  final String? category; // Added category field
  final List<String>? tags; // Dynamic tags
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  final bool inStock; // Stock status
  final int stockCount; // Exact stock quantity

  final bool hasVariations;
  final List<ProductVariation>? variations;

  ProductCardModel({
    this.id,
    required this.image,
    this.images,
    required this.title,
    required this.description,
    required this.price,
    this.mrp,
    required this.unit,
    this.quantity,
    this.category,
    this.tags,
    this.inStock = true,
    this.stockCount = 0,
    this.hasVariations = false,
    this.variations,
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
      'quantity': quantity,
      'category': category,
      'tags': tags,
      'inStock': inStock,
      'stockCount': stockCount,
      'hasVariations': hasVariations,
      'variations': variations?.map((v) => v.toJson()).toList(),
    };
  }

  factory ProductCardModel.fromJson(
    Map<String, dynamic> json, {
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
  }) {
    final bool hasVars = json['hasVariations'] ?? false;
    final List<ProductVariation>? vars = json['variations'] != null
        ? (json['variations'] as List).map((v) => ProductVariation.fromJson(Map<String, dynamic>.from(v))).toList()
        : null;

    double basePrice = (json['price'] ?? 0).toDouble();
    double? baseMrp = json['mrp'] != null ? (json['mrp'] as num).toDouble() : null;
    String baseUnit = json['unit']?.toString() ?? 'unit';
    String? baseQuantity = json['quantity']?.toString() ?? json['weight']?.toString() ?? json['unitQuantity']?.toString() ?? json['unitValue']?.toString();

    if (hasVars && vars != null && vars.isNotEmpty) {
      if (basePrice == 0) basePrice = vars.first.price;
      if (baseMrp == null || baseMrp == 0) baseMrp = vars.first.mrp;
      if (baseUnit == 'unit' || baseUnit.isEmpty) baseUnit = vars.first.unit;
      if (baseQuantity == null || baseQuantity.isEmpty) baseQuantity = vars.first.unitValue;
    }

    String finalUnit = () {
      if (baseQuantity != null && baseQuantity.isNotEmpty) {
        if (baseQuantity.toLowerCase().endsWith(baseUnit.toLowerCase())) {
          return baseQuantity;
        }
        return '$baseQuantity$baseUnit';
      }
      return baseUnit;
    }();

    String imageUrl = json['image']?.toString() ?? '';
    if (imageUrl.isEmpty && json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      imageUrl = json['images'][0].toString();
    }

    return ProductCardModel(
      id: json['id'],
      image: imageUrl,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: basePrice,
      mrp: baseMrp,
      unit: finalUnit,
      quantity: baseQuantity,
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      inStock: json['inStock'] ?? true,
      stockCount: json['stockCount'] != null 
          ? (json['stockCount'] as num).toInt() 
          : (json['inStock'] == false ? 0 : 99),
      hasVariations: hasVars,
      variations: vars,
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
    String? quantity,
    String? category,
    List<String>? tags,
    bool? inStock,
    int? stockCount,
    bool? hasVariations,
    List<ProductVariation>? variations,
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
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
      hasVariations: hasVariations ?? this.hasVariations,
      variations: variations ?? this.variations,
      onTap: onTap ?? this.onTap,
      onAddToCart: onAddToCart ?? this.onAddToCart,
    );
  }
}
