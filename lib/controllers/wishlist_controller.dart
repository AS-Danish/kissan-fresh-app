import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'auth_controller.dart';

class WishlistController extends GetxController {
  // Observable list of wishlist items
  RxList<ProductCardModel> wishlistItems = <ProductCardModel>[].obs;
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _fetchWishlist();
  }

  void _fetchWishlist() async {
    final user = _authController.firebaseUser.value;
    if (user == null) return;

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      List<ProductCardModel> loadedItems = [];
      if (docSnapshot.exists && docSnapshot.data() != null && docSnapshot.data()!.containsKey('wishlist')) {
        List<dynamic> wishlistData = docSnapshot.data()!['wishlist'];
        for (var data in wishlistData) {
          loadedItems.add(ProductCardModel(
            id: data['id'] ?? data['title'],
            title: data['title'] ?? 'Unknown',
            description: data['description'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            image: data['image'] ?? '',
            unit: data['unit'] ?? 'unit',
            category: data['category'],
            inStock: data['inStock'] ?? true,
            tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
            onTap: () {},
            onAddToCart: () {},
          ));
        }
      }
      wishlistItems.value = loadedItems;
    } catch (e) {
      print("Error fetching wishlist: $e");
    }
  }

  // Helper to sync local wishlist with Firestore array
  Future<void> _updateFirestoreWishlist(String uid) async {
    try {
      List<Map<String, dynamic>> data = wishlistItems.map((item) => {
        'id': item.id ?? item.title,
        'title': item.title,
        'description': item.description,
        'price': item.price,
        'image': item.image,
        'unit': item.unit,
        'category': item.category,
        'tags': item.tags,
        'inStock': item.inStock,
      }).toList();

      await _firestore
          .collection('users')
          .doc(uid)
          .set({'wishlist': data}, SetOptions(merge: true));
    } catch (e) {
      print("Error updating wishlist in Firestore: $e");
    }
  }

  // Add item to wishlist
  Future<void> addToWishlist(ProductCardModel product) async {
    if (!isInWishlist(product)) {
      final user = _authController.firebaseUser.value;
      if (user == null) {
        // Redundant check for safety, actual guard is in toggleWishlist now
        return;
      }

      // Ensure that products being added to wishlist get an ID to match safely
      final productToAdd = ProductCardModel(
        id: product.id ?? product.title,
        title: product.title,
        description: product.description,
        price: product.price,
        image: product.image,
        images: product.images,
        unit: product.unit,
         category: product.category,
        inStock: product.inStock,
        tags: product.tags,
        onTap: product.onTap,
        onAddToCart: product.onAddToCart,
      );

      wishlistItems.add(productToAdd);
      await _updateFirestoreWishlist(user.uid);
    }
  }

  // Remove item from wishlist
  Future<void> removeFromWishlist(ProductCardModel product) async {
    final user = _authController.firebaseUser.value;
    if (user == null) return;

    final targetId = product.id ?? product.title;
    wishlistItems.removeWhere((item) => (item.id ?? item.title) == targetId);
    
    await _updateFirestoreWishlist(user.uid);
  }

  // Check if item is in wishlist
  bool isInWishlist(ProductCardModel product) {
    final targetId = product.id ?? product.title;
    return wishlistItems.any((item) => (item.id ?? item.title) == targetId);
  }

  // Toggle wishlist status
  void toggleWishlist(ProductCardModel product) {
    final user = _authController.firebaseUser.value;
    if (user == null) {
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

    if (isInWishlist(product)) {
      removeFromWishlist(product);
    } else {
      addToWishlist(product);
    }
  }
}
