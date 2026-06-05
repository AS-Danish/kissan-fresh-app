import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'cart_controller.dart';
import 'homepage_controller.dart';
import '../services/cache_service.dart';

class ProductsController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final RxList<ProductCardModel> products = <ProductCardModel>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = Get.find<CacheService>();

  // Real-time stream subscription for caching
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // Pagination observables
  RxBool isLoadingProducts = false.obs;
  RxBool isFetchingMore = false.obs;
  RxBool hasMoreProducts = true.obs;

  // Variables to hold the last document for each tab/category for pagination
  final Map<String, DocumentSnapshot?> _lastDocuments = {};

  final int limit = 10;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab and category changes
    ever(homepageController.currentTab, (_) => fetchInitialProducts());
    ever(homepageController.selectedIndex, (_) {
      if (homepageController.currentTab.value == 'Grocery') {
        fetchInitialProducts();
      }
    });
    ever(homepageController.selectedHomeFoodIndex, (_) {
      if (homepageController.currentTab.value == 'HomeFood') {
        fetchInitialProducts();
      }
    });
    fetchInitialProducts();
  }

  String get currentOrigin {
    return homepageController.currentTab.value == 'Grocery'
        ? 'kissan-fresh'
        : 'home-food';
  }

  String get currentCategory {
    if (homepageController.currentTab.value == 'Grocery') {
      final idx = homepageController.selectedIndex.value;
      if (idx >= 0 && idx < homepageController.categories.length) {
        return homepageController.categories[idx].label;
      }
    } else {
      final idx = homepageController.selectedHomeFoodIndex.value;
      if (idx >= 0 && idx < homepageController.homeFoodCategories.length) {
        return homepageController.homeFoodCategories[idx].label;
      }
    }
    return 'All';
  }

  String get currentCacheKey {
    return '${currentOrigin}_$currentCategory';
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchInitialProducts() async {
    final origin = currentOrigin;
    final category = currentCategory;
    final cacheKey = currentCacheKey;

    // Load from cache instantly if available to prevent loading spinners
    final cached = _cacheService.getProducts(cacheKey);
    if (cached.isNotEmpty) {
      final boundData = cached.map((p) {
        return p.copyWith(
          onTap: () {
            Get.toNamed(
              AppRoutes.productDetailsRoute,
              arguments: p,
            );
          },
          onAddToCart: () {
            try {
              final cartController = Get.find<CartController>();
              bool added = cartController.addToCart(p, 1);
              if (added) {
                Get.snackbar(
                  'Added to Cart',
                  '${p.title} added to cart',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF14B8A6),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            } catch (e) {
              debugPrint("CartController not found: $e");
            }
          },
        );
      }).toList();
      products.assignAll(boundData);
      // NOTE: We don't hide the loading indicator here because the UI is already populated.
    } else {
      isLoadingProducts.value = true;
      products.clear();
    }

    try {
      hasMoreProducts.value = true;

      // Cancel previous subscription if switching tabs
      await _productsSubscription?.cancel();

      // Setup a stream listener. This fetches from local cache first, then updates from server if changed.
      Query query = _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin);

      if (category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      _productsSubscription = query
          .limit(limit)
          .snapshots(
            includeMetadataChanges: true,
          ) // Allows observing cache vs server states
          .listen(
            (QuerySnapshot snapshot) {
              if (snapshot.docs.isEmpty) {
                hasMoreProducts.value = false;
                products.value = [];
                _cacheService.saveProducts(cacheKey, []);
                isLoadingProducts.value = false;
                return;
              }

              // Store the last document of the initial load for pagination
              _lastDocuments[cacheKey] = snapshot.docs.last;

              final mappedProducts = snapshot.docs
                  .map((doc) => _mapToProductCardModel(doc))
                  .toList();

              // Only update if there's actually new or changed data. Stream triggers on initial load as well.
              products.value = mappedProducts;
              _cacheService.saveProducts(cacheKey, mappedProducts);

              if (snapshot.docs.length < limit) {
                hasMoreProducts.value = false;
              } else {
                hasMoreProducts.value = true;
              }

              isLoadingProducts.value = false;
            },
            onError: (error) {
              debugPrint("Error in products stream: $error");
              isLoadingProducts.value = false;
            },
          );
    } catch (e) {
      debugPrint("Error setting up initial products stream: $e");
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchNextPage() async {
    final origin = currentOrigin;
    final category = currentCategory;
    final cacheKey = currentCacheKey;
    final lastDoc = _lastDocuments[cacheKey];

    if (isFetchingMore.value || !hasMoreProducts.value || lastDoc == null) {
      return;
    }

    try {
      isFetchingMore.value = true;

      Query query = _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin);

      if (category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      // Use a one-time get() for pagination to avoid compounding streams
      QuerySnapshot querySnapshot = await query
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        hasMoreProducts.value = false;
        return;
      }

      _lastDocuments[cacheKey] = querySnapshot.docs.last;

      final newProducts = querySnapshot.docs
          .map((doc) => _mapToProductCardModel(doc))
          .toList();

      products.addAll(newProducts);
      // Update persistent cache with combined products
      _cacheService.saveProducts(cacheKey, products.toList());

      if (querySnapshot.docs.length < limit) {
        hasMoreProducts.value = false;
      }
    } catch (e) {
      debugPrint("Error fetching next page: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;

    final model = ProductCardModel.fromJson(data);

    return model.copyWith(
      onTap: () {
        Get.toNamed(
          AppRoutes.productDetailsRoute,
          arguments: model,
        );
      },
      onAddToCart: () {
        try {
          final cartController = Get.find<CartController>();
          bool added = cartController.addToCart(model, 1);
          if (added) {
            Get.snackbar(
              'Added to Cart',
              '${model.title} added to cart',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF14B8A6),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          }
        } catch (e) {
          debugPrint("CartController not found: $e");
        }
      },
    );
  }

  // Helper method for navigation using named routes
  static void _navigateToProductDetails({
    required String? id,
    required String image,
    List<String>? images,
    required String title,
    required String description,
    required double price,
    double? mrp,
    required String unit,
    String? quantity,
    String? category,
    List<String>? tags,
    bool inStock = true,
    int stockCount = 0,
  }) {
    Get.toNamed(
      AppRoutes.productDetailsRoute,
      arguments: ProductCardModel(
        id: id,
        image: image,
        images: images,
        title: title,
        description: description,
        price: price,
        mrp: mrp,
        unit: unit,
        quantity: quantity,
        category: category,
        tags: tags,
        inStock: inStock,
        stockCount: stockCount,
        onTap: () {},
        onAddToCart: () {},
      ),
    );
  }
}
