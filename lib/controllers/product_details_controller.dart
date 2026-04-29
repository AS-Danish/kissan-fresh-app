import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import 'cart_controller.dart';
import 'wishlist_controller.dart';
import 'auth_controller.dart';
import '../routes/app_routes.dart';
import '../views/widgets/cart_success_popup.dart';
import 'user_activity_controller.dart';

class ProductDetailsController extends GetxController {
  // Observable quantity
  var quantity = 1.obs;

  Timer? _cartPopupTimer;

  // Observable for current image index
  var currentImageIndex = 0.obs;

  void onImageChanged(int index) {
    currentImageIndex.value = index;
  }

  Rxn<ProductCardModel> observableProduct = Rxn<ProductCardModel>();
  StreamSubscription? _productSubscription;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    observableProduct.value = productData;
    
    // Universally track product view whenever product details are opened
    try {
      Get.find<UserActivityController>().trackView(productData);
    } catch (e) {
      debugPrint("Error tracking product view: $e");
    }
    
    _startProductListener();
    // Check if product is already in wishlist using safe Get.put
    Get.put(WishlistController());
  }

  void _startProductListener() {
    final productId =
        observableProduct.value?.id ?? observableProduct.value?.title;
    if (productId == null) return;

    _productSubscription?.cancel();
    _productSubscription = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final current = observableProduct.value!;

            observableProduct.value = ProductCardModel(
              id: current.id,
              title: current.title,
              description: current.description,
              price: (data['price'] ?? 0).toDouble(),
              mrp: data['mrp'] != null ? (data['mrp'] as num).toDouble() : null,
              image: current.image,
              images: current.images,
              unit: current.unit,
              category: current.category,
              stockCount: (data['stockCount'] ?? 0).toInt(),
              inStock:
                  (data['inStock'] ?? true) && (data['stockCount'] ?? 0) > 0,
              tags: current.tags,
              onTap: current.onTap,
              onAddToCart: current.onAddToCart,
            );
          }
        });
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
    final authController = Get.find<AuthController>();
    if (authController.firebaseUser.value == null) {
      Get.toNamed(AppRoutes.loginScreen);
      Get.snackbar(
        'Login Required',
        'Please login to save favorite items across devices.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0d9488),
        colorText: Colors.white,
      );
      return;
    }

    final wishlistController = Get.find<WishlistController>();
    if (observableProduct.value != null) {
      wishlistController.toggleWishlist(observableProduct.value!);
    }

    final isFav =
        observableProduct.value != null &&
        wishlistController.isInWishlist(observableProduct.value!);

    Get.snackbar(
      isFav ? 'Added to Favorites' : 'Removed from Favorites',
      isFav
          ? '${observableProduct.value?.title} added to your favorites'
          : '${observableProduct.value?.title} removed from favorites',
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
    final authController = Get.find<AuthController>();
    if (authController.firebaseUser.value == null) {
      Get.toNamed(AppRoutes.loginScreen);
      Get.snackbar(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0d9488),
        colorText: Colors.white,
      );
      return;
    }

    try {
      final cartController = Get.find<CartController>();
      final p = observableProduct.value;
      if (p == null) return;

      // Use the centralized addToCart for strict stock enforcement
      bool added = cartController.addToCart(p, quantity.value);

      if (added) {
        Get.dialog(const CartSuccessPopup(), barrierDismissible: true);

        // Automatically close after 2 seconds
        _cartPopupTimer?.cancel();
        _cartPopupTimer = Timer(const Duration(seconds: 2), () {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        });
      }
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
  double get totalPrice =>
      (observableProduct.value?.price ?? 0) * quantity.value;

  @override
  void onClose() {
    _cartPopupTimer?.cancel();
    _productSubscription?.cancel();
    super.onClose();
  }
}
