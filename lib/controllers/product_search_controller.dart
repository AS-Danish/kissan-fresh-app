import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import '../views/screens/product_details_screen.dart';
import 'products_controller.dart';

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
    return [
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
        title: 'Fresh Tomatoes',
        description:
            'Farm fresh red tomatoes, rich in vitamins and perfect for salads',
        price: 45.00,
        unit: 'kg',
        category: 'Vegetables',
        onTap: () => _navigateToDetails(
          'Fresh Tomatoes',
          'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
          'Farm fresh red tomatoes, rich in vitamins and perfect for salads. These tomatoes are sourced directly from local organic farms.',
          45.00,
          'kg',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
        title: 'Amul Milk',
        description: 'Pure and fresh full cream milk',
        price: 28.00,
        unit: 'liter',
        category: 'Dairy',
        onTap: () => _navigateToDetails(
          'Amul Milk',
          'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
          'Pure and fresh full cream milk, homogenized for quality. Perfect for your daily nutrition needs.',
          28.00,
          'liter',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
        title: 'Lays Classic Chips',
        description: 'Crispy and delicious potato chips',
        price: 20.00,
        unit: 'pack',
        category: 'Snacks',
        onTap: () => _navigateToDetails(
          'Lays Classic Chips',
          'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
          'Crispy and delicious potato chips with perfect salt. Made from the finest potatoes.',
          20.00,
          'pack',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
        title: 'Brown Bread',
        description: 'Freshly baked whole wheat bread',
        price: 35.00,
        unit: 'pack',
        category: 'Bakery',
        onTap: () => _navigateToDetails(
          'Brown Bread',
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
          'Freshly baked whole wheat brown bread, high in fiber. Perfect for healthy breakfast.',
          35.00,
          'pack',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80',
        title: 'Green Apples',
        description: 'Crisp and juicy imported apples',
        price: 120.00,
        unit: 'kg',
        category: 'Fruits',
        onTap: () => _navigateToDetails(
          'Green Apples',
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80',
          'Crisp and juicy imported green apples, packed with nutrients. Perfect for eating fresh.',
          120.00,
          'kg',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=500&q=80',
        title: 'Coca Cola',
        description: 'Refreshing carbonated soft drink',
        price: 40.00,
        unit: 'bottle',
        category: 'Beverages',
        onTap: () => _navigateToDetails(
          'Coca Cola',
          'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=500&q=80',
          'Refreshing carbonated soft drink, perfect for any occasion. Best served chilled.',
          40.00,
          'bottle',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
        title: 'Fresh Paneer',
        description: 'Soft and fresh cottage cheese',
        price: 80.00,
        unit: 'pack',
        category: 'Dairy',
        onTap: () => _navigateToDetails(
          'Fresh Paneer',
          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
          'Soft and fresh cottage cheese, perfect for curries. Made from pure milk.',
          80.00,
          'pack',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
        title: 'Basmati Rice',
        description: 'Premium quality aged basmati rice',
        price: 150.00,
        unit: 'kg',
        category: 'Grains',
        onTap: () => _navigateToDetails(
          'Basmati Rice',
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
          'Premium quality aged basmati rice with aromatic flavor. Perfect for biryani.',
          150.00,
          'kg',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&q=80',
        title: 'Organic Carrots',
        description: 'Fresh organic carrots',
        price: 50.00,
        unit: 'kg',
        category: 'Vegetables',
        onTap: () => _navigateToDetails(
          'Organic Carrots',
          'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&q=80',
          'Fresh organic carrots, rich in vitamin A. Perfect for salads and cooking.',
          50.00,
          'kg',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=500&q=80',
        title: 'Green Beans',
        description: 'Fresh green beans',
        price: 60.00,
        unit: 'kg',
        category: 'Vegetables',
        onTap: () => _navigateToDetails(
          'Green Beans',
          'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=500&q=80',
          'Fresh green beans, perfect for stir-fry and curries. Crisp and healthy.',
          60.00,
          'kg',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80',
        title: 'Fresh Bananas',
        description: 'Sweet and ripe bananas',
        price: 40.00,
        unit: 'dozen',
        category: 'Fruits',
        onTap: () => _navigateToDetails(
          'Fresh Bananas',
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80',
          'Sweet and ripe bananas, rich in potassium. Perfect for energy boost.',
          40.00,
          'dozen',
        ),
        onAddToCart: () {},
      ),
      ProductCardModel(
        image:
            'https://images.unsplash.com/photo-1587049352846-4a222e784l67?w=500&q=80',
        title: 'Orange Juice',
        description: 'Fresh squeezed orange juice',
        price: 50.00,
        unit: 'liter',
        category: 'Beverages',
        onTap: () => _navigateToDetails(
          'Orange Juice',
          'https://images.unsplash.com/photo-1587049352846-4a222e784l67?w=500&q=80',
          'Fresh squeezed orange juice, 100% natural with no added sugar.',
          50.00,
          'liter',
        ),
        onAddToCart: () {},
      ),
    ];
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
    String title,
    String image,
    String description,
    double price,
    String unit,
  ) {
    Get.toNamed(
      AppRoutes.productDetailsRoute,
      arguments: ProductCardModel(
        image: image,
        title: title,
        description: description,
        price: price,
        unit: unit,
        onTap: () {},
        onAddToCart: () {},
      ),
    );
  }
}
