import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/product_card_model.dart';
import '../views/screens/product_details_screen.dart';

class ProductsController extends GetxController {
  final products = [
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
      title: 'Fresh Tomatoes',
      description: 'Farm fresh red tomatoes, rich in vitamins and perfect for salads',
      price: 45.00,
      unit: 'kg',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
            title: 'Fresh Tomatoes',
            description: 'Farm fresh red tomatoes, rich in vitamins and perfect for salads. These tomatoes are sourced directly from local organic farms, ensuring the highest quality and freshness. Perfect for cooking, salads, or juices.',
            price: 45.00,
            unit: 'kg',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Fresh Tomatoes to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
      title: 'Amul Milk',
      description: 'Pure and fresh full cream milk, homogenized for quality',
      price: 28.00,
      unit: 'liter',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
            title: 'Amul Milk',
            description: 'Pure and fresh full cream milk, homogenized for quality. Amul milk is known for its richness and purity, perfect for your daily nutrition needs. Delivered fresh every morning.',
            price: 28.00,
            unit: 'liter',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Amul Milk to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
      title: 'Lays Classic Chips',
      description: 'Crispy and delicious potato chips with perfect salt',
      price: 20.00,
      unit: 'pack',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
            title: 'Lays Classic Chips',
            description: 'Crispy and delicious potato chips with perfect salt. Made from the finest potatoes and cooked to perfection. A perfect snack for any time of the day.',
            price: 20.00,
            unit: 'pack',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Lays Classic Chips to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
      title: 'Brown Bread',
      description: 'Freshly baked whole wheat brown bread, high in fiber',
      price: 35.00,
      unit: 'pack',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
            title: 'Brown Bread',
            description: 'Freshly baked whole wheat brown bread, high in fiber. Made with 100% whole wheat flour, perfect for a healthy breakfast or sandwich. Baked fresh daily.',
            price: 35.00,
            unit: 'pack',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Brown Bread to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80',
      title: 'Green Apples',
      description: 'Crisp and juicy imported green apples, packed with nutrients',
      price: 120.00,
      unit: 'kg',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80',
            title: 'Green Apples',
            description: 'Crisp and juicy imported green apples, packed with nutrients. These premium quality apples are perfect for eating fresh or making healthy juices. Rich in fiber and vitamins.',
            price: 120.00,
            unit: 'kg',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Green Apples to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=500&q=80',
      title: 'Coca Cola',
      description: 'Refreshing carbonated soft drink, perfect for any occasion',
      price: 40.00,
      unit: 'bottle',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=500&q=80',
            title: 'Coca Cola',
            description: 'Refreshing carbonated soft drink, perfect for any occasion. The iconic taste of Coca-Cola that everyone loves. Best served chilled.',
            price: 40.00,
            unit: 'bottle',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Coca Cola to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
      title: 'Fresh Paneer',
      description: 'Soft and fresh cottage cheese, perfect for curries',
      price: 80.00,
      unit: 'pack',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
            title: 'Fresh Paneer',
            description: 'Soft and fresh cottage cheese, perfect for curries. Made from pure milk with no preservatives. Ideal for making delicious Indian dishes like paneer tikka, palak paneer, and more.',
            price: 80.00,
            unit: 'pack',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Fresh Paneer to cart');
      },
    ),
    ProductCardModel(
      image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
      title: 'Basmati Rice',
      description: 'Premium quality aged basmati rice with aromatic flavor',
      price: 150.00,
      unit: 'kg',
      onTap: () {
        Get.to(() => ProductDetailsScreen(
          product: ProductCardModel(
            image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
            title: 'Basmati Rice',
            description: 'Premium quality aged basmati rice with aromatic flavor. Long grain rice that is perfect for biryani, pulao, and other rice dishes. Aged for enhanced taste and aroma.',
            price: 150.00,
            unit: 'kg',
            onTap: () {},
            onAddToCart: () {},
          ),
        ));
      },
      onAddToCart: () {
        debugPrint('Adding Basmati Rice to cart');
      },
    ),
  ];
}