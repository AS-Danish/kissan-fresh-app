import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'auth_controller.dart';

class WishlistController extends GetxController {
  // Observable list of wishlist items
  RxList<ProductCardModel> wishlistItems = <ProductCardModel>[].obs;
  // Real-time product data map: productId -> product data
  RxMap<String, Map<String, dynamic>> realTimeProductData =
      <String, Map<String, dynamic>>{}.obs;

  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _productsSubscription;
  Worker? _wishlistWorker;

  @override
  void onInit() {
    super.onInit();
    
    // Start listening to product changes whenever wishlistItems changes
    _wishlistWorker = ever(wishlistItems, (_) {
      _updateProductsSubscription();
    });
    
    // Initial fetch from cache and network
    _fetchWishlist();
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    _wishlistWorker?.dispose();
    super.onClose();
  }

  void _updateProductsSubscription() {
    _productsSubscription?.cancel();

    final productIds =
        wishlistItems
            .map((item) => item.id)
            .where((id) => id != null)
            .cast<String>()
            .toList();

    if (productIds.isEmpty) {
      realTimeProductData.clear();
      return;
    }

    // Split into chunks if needed, but for wishlist we limit to top 30 for real-time
    final limitedIds = productIds.take(30).toList();

    _productsSubscription =
        _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: limitedIds)
            .snapshots()
            .listen(
              (snapshot) {
                final Map<String, Map<String, dynamic>> newData = {};
                for (var doc in snapshot.docs) {
                  newData[doc.id] = doc.data();
                }
                realTimeProductData.assignAll(newData);
              },
              onError: (e) => debugPrint("Error in wishlist products stream: $e"),
            );
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
      if (docSnapshot.exists &&
          docSnapshot.data() != null &&
          docSnapshot.data()!.containsKey('wishlist')) {
        List<dynamic> wishlistData = docSnapshot.data()!['wishlist'];

        // Save raw network response to Box for next startup
        box.put(user.uid, wishlistData);

        for (var data in wishlistData) {
          loadedItems.add(_mapToProductCardModel(data as Map<String, dynamic>));
        }
      }
      wishlistItems.value = loadedItems;
      
      // Update real-time subscription immediately after fetch
      _updateProductsSubscription();

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
      mrp: data['mrp'] != null ? (data['mrp'] as num).toDouble() : null,
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
      List<Map<String, dynamic>> data = wishlistItems
          .map(
            (item) => {
              'id': item.id ?? item.title,
              'title': item.title,
              'description': item.description,
              'price': item.price,
              'mrp': item.mrp,
              'image': item.image,
              'unit': item.unit,
              'category': item.category,
              'tags': item.tags,
              'inStock': item.inStock,
              'stockCount': item.stockCount,
              'images': item.images,
            },
          )
          .toList();

      // Update to Local Hive instantly
      final box = Hive.box('wishlist_box');
      box.put(uid, data);

      await _firestore.collection('users').doc(uid).set({
        'wishlist': data,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating wishlist in Firestore: $e");
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
        mrp: product.mrp,
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
        backgroundColor: const Color(0xFF14B8A6),
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
