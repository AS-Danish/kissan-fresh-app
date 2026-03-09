import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/product_data.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import '../views/screens/product_details_screen.dart';
import 'products_controller.dart';
import 'cart_controller.dart';

class ProductSearchController extends GetxController {
  final ProductsController productsController = Get.find<ProductsController>();

  RxString searchQuery = ''.obs;
  RxString selectedCategory = 'All'.obs;

  // Categories with icons and colors
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'color': const Color(0xFF0d9488),
    },
    {
      'name': 'Vegetables',
      'icon': Icons.eco_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Fruits',
      'icon': Icons.apple_outlined,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Dairy',
      'icon': Icons.coffee_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Bakery',
      'icon': Icons.bakery_dining_outlined,
      'color': const Color(0xFFFF9800),
    },
    {
      'name': 'Beverages',
      'icon': Icons.local_drink_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Snacks',
      'icon': Icons.fastfood_outlined,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Grains',
      'icon': Icons.grass_outlined,
      'color': const Color(0xFF92400E),
    },
  ];

  // All products with categories
  List<ProductCardModel> get allProducts {
    return ProductData.products.map((product) {
      return ProductCardModel(
        id: product.id,
        image: product.image,
        images: product.images,
        title: product.title,
        description: product.description,
        price: product.price,
        unit: product.unit,
        category: product.category,
        onTap: () => _navigateToDetails(
          product.id,
          product.title,
          product.image,
          product.images,
          product.description,
          product.price,
          product.unit,
        ),
        onAddToCart: () {
          try {
            bool added = Get.find<CartController>().addToCart(
              ProductCardModel(
                id: product.id,
                image: product.image,
                images: product.images,
                title: product.title,
                description: product.description,
                price: product.price,
                unit: product.unit,
                category: product.category,
                onTap: () {},
                onAddToCart: () {},
              ),
              1, // quantity
            );
            if (added) {
              Get.snackbar(
                'Added to Cart',
                '${product.title} added to cart',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF10B981),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            }
          } catch (e) {
            debugPrint("CartController not found: $e");
          }
        },
      );
    }).toList();
  }

  // Filtered products based on search and category
  List<ProductCardModel> get filteredProducts {
    var products = allProducts;

    // Filter by category
    if (selectedCategory.value != 'All') {
      products = products
          .where((p) => p.category == selectedCategory.value)
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      products = products.where((product) {
        return product.title.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            product.description.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            (product.category ?? '').toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    return products;
  }

  void _navigateToDetails(
    String? id,
    String title,
    String image,
    List<String>? images,
    String description,
    double price,
    String unit,
  ) {
    Get.toNamed(
      AppRoutes.productDetailsRoute,
      arguments: ProductCardModel(
        id: id,
        image: image,
        images: images,
        title: title,
        description: description,
        price: price,
        unit: unit,
        onTap: () {}, // Recursive navigation not needed here as we are already navigating
        onAddToCart: () {
           // We need to find the cart controller dynamically as this closure might be called later
           try {
             final cartController = Get.find<CartController>();
              bool added = cartController.addToCart(
                ProductCardModel(
                  image: image,
                  images: images,
                  title: title,
                  description: description,
                  price: price,
                  unit: unit,
                  onTap: () {},
                  onAddToCart: () {},
                ),
                1
              );
              if (added) {
                Get.snackbar(
                  'Added to Cart',
                  '$title added to cart',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
           } catch (e) {
             debugPrint("CartController not found: $e");
           }
        },
      ),
    );
  }
}
