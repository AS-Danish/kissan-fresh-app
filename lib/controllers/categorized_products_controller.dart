import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'cart_controller.dart';
import 'homepage_controller.dart';
import '../services/cache_service.dart';

class CategorizedProductsController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = Get.find<CacheService>();

  // Map of category name to list of products
  final RxMap<String, List<ProductCardModel>> categorizedProducts =
      <String, List<ProductCardModel>>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab changes to fetch categorized products for the correct origin
    ever(homepageController.currentTab, (_) {
      fetchCategorizedProducts();
    });
    
    // Also listen to categories loading for the first time
    ever(homepageController.categories, (_) {
      if (homepageController.currentTab.value == 'Grocery') {
        fetchCategorizedProducts();
      }
    });
    ever(homepageController.homeFoodCategories, (_) {
      if (homepageController.currentTab.value == 'HomeFood') {
        fetchCategorizedProducts();
      }
    });

    fetchCategorizedProducts();
  }

  String get currentOrigin {
    return homepageController.currentTab.value == 'Grocery'
        ? 'kissan-fresh'
        : 'home-food';
  }

  // Gets the relevant category names for the current origin
  List<String> get currentCategories {
    if (currentOrigin == 'kissan-fresh') {
      return homepageController.categories
          .where((c) => c.label != "All")
          .map((c) => c.label)
          .toList();
    } else {
      return homepageController.homeFoodCategories
          .where((c) => c.label != "All")
          .map((c) => c.label)
          .toList();
    }
  }

  Future<void> fetchCategorizedProducts() async {
    try {
      final categoriesList = currentCategories;
      final origin = currentOrigin;

      // Load from cache first
      final cachedData = _cacheService.getCategorizedProducts(origin);
      if (cachedData.isNotEmpty) {
        // Re-bind onTap handlers because they are lost during serialization
        final boundData = cachedData.map((category, products) {
          return MapEntry(
            category,
            products.map((p) {
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
            }).toList(),
          );
        });
        categorizedProducts.assignAll(boundData);
        // We still proceed to fetch in background to ensure we have the latest variations and data.
        // return; // Removed early return so cache gets updated with new variation models.
      } else {
        isLoading.value = true;
        categorizedProducts.clear();
      }

      // For performance and limits, we process categories in chunks of 3
      for (int i = 0; i < categoriesList.length; i += 3) {
        final chunk = categoriesList.skip(i).take(3);
        List<Future<void>> chunkTasks = [];
        for (String category in chunk) {
          chunkTasks.add(_fetchProductsForCategory(category, origin));
        }
        await Future.wait(chunkTasks);
        // Small delay between chunks to keep main thread free
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint("Error fetching categorized products: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchProductsForCategory(String category, String origin) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin)
          .where('category', isEqualTo: category)
          .limit(
            6,
          ) // limit to 6 products per category for the horizontal scroll
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<ProductCardModel> products = querySnapshot.docs
            .map((doc) => _mapToProductCardModel(doc))
            .toList();
        categorizedProducts[category] = products;
        // Save to persistent cache
        _cacheService.saveCategorizedProducts(origin, categorizedProducts);
      }
    } catch (e) {
      debugPrint("Error fetching category $category: $e");
    }
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Inject ID into the map

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
