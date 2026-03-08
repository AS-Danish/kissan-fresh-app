import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/product_card_model.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';

class ProductDetailsController extends GetxController {
  // Observable quantity
  var quantity = 1.obs;

  // Observable for current image index
  var currentImageIndex = 0.obs;

  void onImageChanged(int index) {
    currentImageIndex.value = index;
  }

  late ProductCardModel product;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    product = productData;
    // Check if product is already in wishlist using safe Get.put
    Get.put(WishlistController());
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
    final wishlistController = Get.find<WishlistController>();
    wishlistController.toggleWishlist(product);
    
    final isFav = wishlistController.isInWishlist(product);

    Get.snackbar(
      isFav ? 'Added to Favorites' : 'Removed from Favorites',
      isFav
          ? '${product.title} added to your favorites'
          : '${product.title} removed from favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isFav ? const Color(0xFF10B981) : Colors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Add product to cart
  void addToCart() {
    try {
      final cartController = Get.put(CartController());
      final productId = product.id ?? product.title;

      // Ensure local state mapped logic runs directly here
      final cartItem = CartItem(
        id: productId,
        name: product.title,
        quantity: product.unit,
        price: product.price,
        image: product.image,
        count: quantity.value,
      );

      final existingIndex = cartController.cartItems.indexWhere((i) => i.id == productId);

      if (existingIndex >= 0) {
        // Item already exists, increase count
        cartController.cartItems[existingIndex].count += quantity.value;
        cartController.cartItems.refresh();
      } else {
        // New item, add to cart
        cartController.cartItems.add(cartItem);
      }

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