import 'package:kissanfresh/features/cart/application/cart_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kissanfresh/features/catalog/domain/product_card_model.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';
import 'package:kissanfresh/core/services/cache_service.dart';

class CategorizedProductsController extends FeatureController {
  final Ref ref;

  CategorizedProductsController(this.ref);

  late final HomepageController homepageController = ref.read(
    homepageControllerProvider,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CacheService _cacheService = ref.read(cacheServiceProvider);

  // Map of category name to list of products
  final ObservableMap<String, List<ProductCardModel>> categorizedProducts =
      ObservableMap(<String, List<ProductCardModel>>{});
  final Observable<bool> isLoading = Observable(false);
  int _requestGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab changes to fetch categorized products for the correct origin
    observeField(homepageController.currentTab, (_) {
      fetchCategorizedProducts();
    });

    // Also listen to categories loading for the first time
    observeField(homepageController.categories, (_) {
      if (homepageController.currentTab.value == 'Grocery') {
        fetchCategorizedProducts();
      }
    });
    observeField(homepageController.homeFoodCategories, (_) {
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
          .where((category) => category.label != 'All')
          .map((category) => category.label)
          .toList();
    } else {
      return homepageController.homeFoodCategories
          .where((c) => c.label != "All")
          .map((c) => c.label)
          .toList();
    }
  }

  Future<void> fetchCategorizedProducts() async {
    final requestGeneration = ++_requestGeneration;
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
                  AppNavigator.toNamed(
                    AppRoutes.productDetailsRoute,
                    arguments: p,
                  );
                },
                onAddToCart: () {
                  try {
                    final cartController = ref.read(cartControllerProvider);
                    bool added = cartController.addToCart(p, 1);
                    if (added) {
                      CustomSnackBar.show(
                        'Added to Cart',
                        '${p.title} added to cart',
                        snackPosition: SnackPosition.bottom,
                        backgroundColor: AppNavigator.theme.primaryColor,
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

      final refreshedData = Map<String, List<ProductCardModel>>.from(
        categorizedProducts,
      );

      // Keep network concurrency bounded, then publish results in batches so
      // a large catalog does not rebuild the home feed for every response.
      for (int i = 0; i < categoriesList.length; i += 3) {
        final chunk = categoriesList.skip(i).take(3).toList();
        final results = await Future.wait(
          chunk.map(
            (category) =>
                _fetchProductsForCategory(category, origin, requestGeneration),
          ),
        );
        if (requestGeneration != _requestGeneration) return;
        for (var index = 0; index < chunk.length; index++) {
          final products = results[index];
          if (products != null) refreshedData[chunk[index]] = products;
        }

        if (i == 0 || i + 3 >= categoriesList.length) {
          categorizedProducts.assignAll(refreshedData);
        }
      }
      await _cacheService.saveCategorizedProducts(origin, categorizedProducts);
    } catch (e) {
      debugPrint("Error fetching categorized products: $e");
    } finally {
      if (requestGeneration == _requestGeneration) {
        isLoading.value = false;
      }
    }
  }

  Future<List<ProductCardModel>?> _fetchProductsForCategory(
    String category,
    String origin,
    int requestGeneration,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin)
          .where('category', isEqualTo: category)
          .limit(6)
          .get(const GetOptions(source: Source.serverAndCache));

      if (requestGeneration != _requestGeneration || origin != currentOrigin) {
        return null;
      }
      return querySnapshot.docs
          .map((doc) => _mapToProductCardModel(doc))
          .toList();
    } catch (e) {
      debugPrint("Error fetching category $category: $e");
    }
    return null;
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Inject ID into the map

    final model = ProductCardModel.fromJson(data);

    return model.copyWith(
      onTap: () {
        AppNavigator.toNamed(AppRoutes.productDetailsRoute, arguments: model);
      },
      onAddToCart: () {
        try {
          final cartController = ref.read(cartControllerProvider);
          bool added = cartController.addToCart(model, 1);
          if (added) {
            CustomSnackBar.show(
              'Added to Cart',
              '${model.title} added to cart',
              snackPosition: SnackPosition.bottom,
              backgroundColor: AppNavigator.theme.primaryColor,
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
}

final categorizedProductsControllerProvider = Provider(
  (ref) => startController(ref, CategorizedProductsController(ref)),
);
