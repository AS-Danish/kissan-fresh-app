import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'cart_controller.dart';
import 'orders_controller.dart';

class UserActivityController extends GetxController {
  late Box _activityBox;
  final RxList<ProductCardModel> personalizedProducts = <ProductCardModel>[].obs;
  // Real-time product data map: productId -> product data
  RxMap<String, Map<String, dynamic>> realTimeProductData =
      <String, Map<String, dynamic>>{}.obs;
  
  static const String _recentViewsKey = 'recent_views';
  static const String _viewCountsKey = 'view_counts';
  static const int _maxItems = 12;
  static const int _viewThreshold = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _productsSubscription;
  Worker? _personalizedWorker;

  @override
  void onInit() {
    super.onInit();
    _activityBox = Hive.box('user_activity');
    _loadPersonalizedData();
    
    // Start listening to product changes whenever personalizedProducts changes
    _personalizedWorker = ever(personalizedProducts, (_) {
      _updateProductsSubscription();
    });

    // Manually trigger initial subscription to ensure real-time data from start
    _updateProductsSubscription();
    
    // Refresh when orders change
    final ordersController = Get.find<OrdersController>();
    ever(ordersController.orders, (_) => _loadPersonalizedData());
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    _personalizedWorker?.dispose();
    super.onClose();
  }

  void _updateProductsSubscription() {
    _productsSubscription?.cancel();

    final productIds =
        personalizedProducts
            .map((item) => item.id)
            .where((id) => id != null)
            .cast<String>()
            .toList();

    if (productIds.isEmpty) {
      realTimeProductData.clear();
      return;
    }

    _productsSubscription =
        _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: productIds)
            .snapshots()
            .listen(
              (snapshot) {
                final Map<String, Map<String, dynamic>> newData = {};
                for (var doc in snapshot.docs) {
                  newData[doc.id] = doc.data();
                }
                realTimeProductData.assignAll(newData);
              },
              onError: (e) => debugPrint("Error in personalized products stream: $e"),
            );
  }

  void _loadPersonalizedData() {
    final List<ProductCardModel> combined = [];
    final Set<String> uniqueIds = {};

    // 1. Load from Recent Views (stored in Hive)
    final String? cachedViews = _activityBox.get(_recentViewsKey);
    if (cachedViews != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedViews);
        for (var item in decoded) {
          final productData = Map<String, dynamic>.from(item);
          final product = ProductCardModel.fromJson(
            productData,
            onTap: () => _navigateToProductDetails(
              ProductCardModel.fromJson(productData),
            ),
            onAddToCart: () {
              try {
                final cartController = Get.find<CartController>();
                final productModel = ProductCardModel.fromJson(productData);
                bool added = cartController.addToCart(productModel, 1);
                if (added) {
                  Get.snackbar(
                    'Added to Cart',
                    '${productModel.title} added to cart',
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
          if (product.id != null && !uniqueIds.contains(product.id)) {
            combined.add(product);
            uniqueIds.add(product.id!);
          }
        }
      } catch (e) {
        debugPrint('Error decoding recent views: $e');
      }
    }

    // 2. Load from Orders (if logged in)
    try {
      final ordersController = Get.find<OrdersController>();
      for (var order in ordersController.orders) {
        for (var item in order.items) {
          // We only have basic info in order items, but we can construct a ProductCardModel
          // Or we can just use what we have. 
          // Note: OrderItem might not have the full ProductCardModel structure.
          if (item.productId != null && !uniqueIds.contains(item.productId)) {
            combined.add(
              ProductCardModel(
                id: item.productId,
                title: item.title,
                image: item.image,
                price: item.price.toDouble(),
                unit: item.unit,
                stockCount: 99, // default to in stock for reordering
                inStock: true,
                description: "Previously ordered",
                onTap: () => _navigateToProductDetails(
                  ProductCardModel(
                    id: item.productId,
                    title: item.title,
                    image: item.image,
                    price: item.price.toDouble(),
                    unit: item.unit,
                    description: "Previously ordered",
                    onTap: () {},
                    onAddToCart: () {},
                  ),
                ),
                onAddToCart: () {
                  try {
                    final cartController = Get.find<CartController>();
                    final productModel = ProductCardModel(
                      id: item.productId,
                      title: item.title,
                      image: item.image,
                      price: item.price.toDouble(),
                      unit: item.unit,
                      stockCount: 99,
                      inStock: true,
                      description: "Previously ordered",
                      onTap: () {},
                      onAddToCart: () {},
                    );
                    bool added = cartController.addToCart(productModel, 1);
                    if (added) {
                      Get.snackbar(
                        'Added to Cart',
                        '${productModel.title} added to cart',
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
              ),
            );
            uniqueIds.add(item.productId!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting items from orders: $e');
    }

    // Limit and update
    personalizedProducts.value = combined.take(_maxItems).toList();
  }

  void trackView(ProductCardModel product) {
    if (product.id == null) return;

    // 1. Update view count
    final String? cachedCounts = _activityBox.get(_viewCountsKey);
    Map<String, dynamic> viewCounts = {};
    if (cachedCounts != null) {
      try {
        viewCounts = Map<String, dynamic>.from(jsonDecode(cachedCounts));
      } catch (e) {
        debugPrint('Error decoding view counts: $e');
      }
    }

    final int currentCount = (viewCounts[product.id] ?? 0) + 1;
    viewCounts[product.id!] = currentCount;
    _activityBox.put(_viewCountsKey, jsonEncode(viewCounts));

    // 2. If threshold reached, add/update in recent views
    if (currentCount >= _viewThreshold) {
      _addToRecentViews(product);
    }
  }

  void trackAddToCart(ProductCardModel product) {
    // Adding to cart directly qualifies the product
    _addToRecentViews(product);
  }

  void _addToRecentViews(ProductCardModel product) {
    if (product.id == null) return;

    final String? cachedViews = _activityBox.get(_recentViewsKey);
    List<Map<String, dynamic>> viewsList = [];

    if (cachedViews != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedViews);
        viewsList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error decoding views list: $e');
      }
    }

    // Remove if exists (to bring to front)
    viewsList.removeWhere((item) => item['id'] == product.id);

    // Add to front
    viewsList.insert(0, product.toJson());

    // Limit size
    if (viewsList.length > _maxItems) {
      viewsList = viewsList.sublist(0, _maxItems);
    }

    // Save
    _activityBox.put(_recentViewsKey, jsonEncode(viewsList));
    
    // Refresh UI
    _loadPersonalizedData();
  }

  void _navigateToProductDetails(ProductCardModel product) {
    Get.toNamed(
      AppRoutes.productDetailsRoute,
      arguments: product,
    );
  }
}
