import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/product_data.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'homepage_controller.dart';

class ProductsController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final RxList<ProductCardModel> products = <ProductCardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initial load
    _updateProducts();
    
    // Listen to tab changes
    ever(homepageController.currentTab, (_) => _updateProducts());
  }

  void _updateProducts() {
    final sourceProducts = homepageController.currentTab.value == 'Grocery'
        ? ProductData.products
        : ProductData.homeFoodProducts;

    products.value = sourceProducts.map((product) {
      return ProductCardModel(
        id: product.id,
        image: product.image,
        title: product.title,
        description: product.description,
        price: product.price,
        unit: product.unit,
        category: product.category,
        onTap: () => _navigateToProductDetails(
          image: product.image,
          title: product.title,
          description: product.description,
          price: product.price,
          unit: product.unit,
        ),
        onAddToCart: () {
          debugPrint('Adding ${product.title} to cart');
        },
      );
    }).toList();
  }

  // Helper method for navigation using named routes
  static void _navigateToProductDetails({
    required String image,
    required String title,
    required String description,
    required double price,
    required String unit,
  }) {
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
