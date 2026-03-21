import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'auth_controller.dart';

class WishlistController extends GetxController {
  // Observable list of wishlist items
  RxList<ProductCardModel> wishlistItems = <ProductCardModel>[].obs;
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _productsSubscription;

  @override
  void onInit() {
    super.onInit();
    _fetchWishlist();
    _startProductsListener();
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    super.onClose();
  }

  void _startProductsListener() {
    // Optimization: Don't listen to the entire products collection.
    // Instead, we could listen to specific products if needed, but for now
    // let's rely on manual sync or explicit product fetches.
  }

  void _syncWishlistWithSnapshot(QuerySnapshot snapshot) {
    if (wishlistItems.isEmpty) return;

    bool changed = false;
    final productDataMap = {for (var doc in snapshot.docs) doc.id: doc.data()};

      for (int i = 0; i < wishlistItems.length; i++) {
        final item = wishlistItems[i];
        final productId = item.id ?? item.title;
        
        if (productDataMap.containsKey(productId)) {
          final data = productDataMap[productId]! as Map<String, dynamic>;
          final double freshPrice = (data['price'] ?? 0).toDouble();
          final int freshStockCount = (data['stockCount'] ?? 0).toInt();
          final bool freshStockStatus = (data['inStock'] ?? true) && freshStockCount > 0;

          if (item.price != freshPrice || 
              item.inStock != freshStockStatus || 
              item.stockCount != freshStockCount) {
            
            wishlistItems[i] = ProductCardModel(
              id: item.id,
              title: item.title,
              description: item.description,
              price: freshPrice,
              image: item.image,
              images: item.images,
              unit: item.unit,
              category: item.category,
              inStock: freshStockStatus,
              stockCount: freshStockCount,
              tags: item.tags,
              onTap: item.onTap,
              onAddToCart: item.onAddToCart,
            );
            changed = true;
          }
        }
      }

      if (changed) {
        wishlistItems.refresh();
      }
  }

  void _fetchWishlist() async {
    final user = _authController.firebaseUser.value;
    if (user == null) return;

    final box = Hive.box('wishlist_box');
    
    // First: Load from local cache instantly
    if (box.containsKey(user.uid)) {
      final cachedData = box.get(user.uid) as List<dynamic>?;
      if (cachedData != null) {
        List<ProductCardModel> loadedItems = [];
        for (var data in cachedData) {
            final mapData = Map<String, dynamic>.from(data as Map);
            loadedItems.add(_mapToProductCardModel(mapData));
        }
        wishlistItems.value = loadedItems;
      }
    }

    // Second: Silent fetch from Firestore to ensure synchronization
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      List<ProductCardModel> loadedItems = [];
      if (docSnapshot.exists && docSnapshot.data() != null && docSnapshot.data()!.containsKey('wishlist')) {
        List<dynamic> wishlistData = docSnapshot.data()!['wishlist'];
        
        // Save raw network response to Box for next startup
        box.put(user.uid, wishlistData);

        for (var data in wishlistData) {
          loadedItems.add(_mapToProductCardModel(data as Map<String, dynamic>));
        }
      }
      wishlistItems.value = loadedItems;
      
      wishlistItems.value = loadedItems;
      
      // Optimization: Removed full collection fetch for sync.
      // Syncing should be done per-item when needed or when a product is viewed.
    } catch (e) {
      debugPrint("Error fetching wishlist from network: $e");
    }
  }

  ProductCardModel _mapToProductCardModel(Map<String, dynamic> data) {
    final int stockCount = (data['stockCount'] ?? 0).toInt();
    final bool inStock = (data['inStock'] ?? true) && stockCount > 0;
    
    return ProductCardModel(
      id: data['id'] ?? data['title'],
      title: data['title'] ?? 'Unknown',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      image: data['image'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      unit: data['unit'] ?? 'unit',
      category: data['category'],
      inStock: inStock,
      stockCount: stockCount,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      onTap: () {},
      onAddToCart: () {},
    );
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
        'images': item.images,
      }).toList();

      // Update to Local Hive instantly
      final box = Hive.box('wishlist_box');
      box.put(uid, data);

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
