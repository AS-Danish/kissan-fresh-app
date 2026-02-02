import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/product_card_model.dart';
import 'cart_controller.dart';

class ProductDetailsController extends GetxController {
  // Observable quantity
  var quantity = 1.obs;

  // Observable for favorite status
  var isFavorite = false.obs;

  late ProductCardModel product;
  late CartController cartController;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    product = productData;
  }

  @override
  void onInit() {
    super.onInit();

    // Get CartController instance
    try {
      cartController = Get.find<CartController>();
    } catch (e) {
      // If CartController is not found, you may need to initialize it
      debugPrint('CartController not found: $e');
    }
  }

  /// Increase quantity
  void increaseQuantity() {
    quantity.value++;
  }

  /// Decrease quantity (minimum 1)
  void decreaseQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  /// Toggle favorite status
  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
    // Save to favorites
    // saveFavoriteStatus(product.id, isFavorite.value);

    Get.snackbar(
      isFavorite.value ? 'Added to Favorites' : 'Removed from Favorites',
      isFavorite.value
          ? '${product.title} added to your favorites'
          : '${product.title} removed from favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Add product to cart
  void addToCart() {
    try {
      cartController.addToCart(product, quantity.value);

      Get.snackbar(
        'Added to Cart',
        '${product.title} (x${quantity.value}) added to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      // Optionally reset quantity after adding to cart
      // quantity.value = 1;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      Get.snackbar(
        'Error',
        'Failed to add to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Calculate total price
  double get totalPrice => product.price * quantity.value;

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}