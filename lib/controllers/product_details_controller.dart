import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/product_card_model.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';

class ProductDetailsController extends GetxController {
  // Observable quantity
  var quantity = 1.obs;

  // Observable for favorite status
  var isFavorite = false.obs;


  late ProductCardModel product;
  late CartController cartController;
  late WishlistController wishlistController;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    product = productData;
    // Check if product is already in wishlist
    if (Get.isRegistered<WishlistController>()) {
      wishlistController = Get.find<WishlistController>();
      isFavorite.value = wishlistController.isInWishlist(product);
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Get CartController instance
    try {
      cartController = Get.find<CartController>();
    } catch (e) {
      debugPrint('CartController not found: $e');
    }
    
    // Get WishlistController instance
    try {
       if (!Get.isRegistered<WishlistController>()) {
          Get.put(WishlistController());
       }
      wishlistController = Get.find<WishlistController>();
    } catch (e) {
      debugPrint('WishlistController not found: $e');
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
    wishlistController.toggleWishlist(product);
    isFavorite.value = wishlistController.isInWishlist(product);

    Get.snackbar(
      isFavorite.value ? 'Added to Favorites' : 'Removed from Favorites',
      isFavorite.value
          ? '${product.title} added to your favorites'
          : '${product.title} removed from favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isFavorite.value ? const Color(0xFF10B981) : Colors.grey,
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