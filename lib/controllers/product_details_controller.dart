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
  // Observable list for similar products
  var similarProducts = <ProductCardModel>[].obs;
  var isLoadingSimilarProducts = false.obs;
  // Observable quantity
  var quantity = 1.obs;

  Timer? _cartPopupTimer;

  // Observable for current image index
  var currentImageIndex = 0.obs;

  void onImageChanged(int index) {
    currentImageIndex.value = index;
  }

  // Observable for selected variation
  var selectedVariation = Rxn<ProductVariation>();

  Rxn<ProductCardModel> observableProduct = Rxn<ProductCardModel>();
  StreamSubscription? _productSubscription;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    observableProduct.value = productData;
    
    if (productData.hasVariations && productData.variations != null && productData.variations!.isNotEmpty) {
      selectedVariation.value = productData.variations!.first;
    }


    // Universally track product view whenever product details are opened
    try {
      Get.find<UserActivityController>().trackView(productData);
    } catch (e) {
      debugPrint("Error tracking product view: $e");
    }
    
    _startProductListener();
    _fetchSimilarProducts(productData);
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
              unit: () {
                String baseUnit = data['unit']?.toString() ?? current.unit;
                String? prefix;
                if (data['quantity'] != null && data['quantity'].toString().isNotEmpty) {
                  prefix = data['quantity'].toString();
                } else if (data['weight'] != null && data['weight'].toString().isNotEmpty) {
                  prefix = data['weight'].toString();
                } else if (data['unitQuantity'] != null && data['unitQuantity'].toString().isNotEmpty) {
                  prefix = data['unitQuantity'].toString();
                } else if (data['unitValue'] != null && data['unitValue'].toString().isNotEmpty) {
                  prefix = data['unitValue'].toString();
                }
                if (prefix != null) {
                  if (prefix.toLowerCase().endsWith(baseUnit.toLowerCase())) {
                    return prefix;
                  }
                  return '$prefix$baseUnit';
                }
                return baseUnit;
              }(),
              quantity: data['quantity']?.toString() ?? data['weight']?.toString() ?? data['unitQuantity']?.toString() ?? data['unitValue']?.toString() ?? current.quantity,
              category: current.category,
              stockCount: (data['stockCount'] ?? 0).toInt(),
              inStock:
                  (data['inStock'] ?? true) && (data['stockCount'] ?? 0) > 0,
              tags: current.tags,
              hasVariations: data['hasVariations'] ?? false,
              variations: data['variations'] != null
                  ? (data['variations'] as List).map((v) => ProductVariation.fromJson(Map<String, dynamic>.from(v))).toList()
                  : current.variations,
              onTap: current.onTap,
              onAddToCart: current.onAddToCart,
            );

            // Maintain selected variation
            if (observableProduct.value!.hasVariations && observableProduct.value!.variations != null && observableProduct.value!.variations!.isNotEmpty) {
              if (selectedVariation.value != null) {
                final existing = observableProduct.value!.variations!.firstWhereOrNull((v) => 
                  (v.id != null && v.id == selectedVariation.value!.id) || 
                  (v.id == null && v.unit == selectedVariation.value!.unit && v.unitValue == selectedVariation.value!.unitValue)
                );
                if (existing != null) {
                  selectedVariation.value = existing;
                } else {
                  selectedVariation.value = observableProduct.value!.variations!.first;
                }
              } else {
                selectedVariation.value = observableProduct.value!.variations!.first;
              }
            }
          }
        });
  }

  Future<void> _fetchSimilarProducts(ProductCardModel productData) async {
    try {
      isLoadingSimilarProducts.value = true;
      similarProducts.clear();

      final List<ProductCardModel> fetchedProducts = [];
      
      // 1. Fetch from the same category
      if (productData.category != null && productData.category!.isNotEmpty && productData.category != 'All') {
        final query = FirebaseFirestore.instance.collection('products')
            .where('category', isEqualTo: productData.category)
            .limit(11);
        final snapshot = await query.get();
        
        for (var doc in snapshot.docs) {
          if (doc.id == productData.id) continue; // Skip the current product
          
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          try {
            fetchedProducts.add(_mapSimilarProduct(data));
          } catch (e) {
            debugPrint("Error parsing similar product: $e");
          }
          
          if (fetchedProducts.length >= 10) break;
        }
      }

      // 2. If we still need more products, fetch from other categories
      if (fetchedProducts.length < 10) {
        int remaining = 10 - fetchedProducts.length;
        Query fallbackQuery = FirebaseFirestore.instance.collection('products');
        
        if (productData.category != null && productData.category!.isNotEmpty && productData.category != 'All') {
          fallbackQuery = fallbackQuery.where('category', isNotEqualTo: productData.category);
        }
        
        final fallbackSnapshot = await fallbackQuery.limit(remaining + 1).get();
        
        for (var doc in fallbackSnapshot.docs) {
          if (doc.id == productData.id) continue;
          
          if (fetchedProducts.any((p) => p.id == doc.id)) continue;
          
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          try {
            fetchedProducts.add(_mapSimilarProduct(data));
          } catch (e) {
            debugPrint("Error parsing similar product: $e");
          }
          
          if (fetchedProducts.length >= 10) break;
        }
      }
      
      similarProducts.value = fetchedProducts;
    } catch (e) {
      debugPrint("Error fetching similar products: $e");
    } finally {
      isLoadingSimilarProducts.value = false;
    }
  }

  ProductCardModel _mapSimilarProduct(Map<String, dynamic> data) {
    final model = ProductCardModel.fromJson(data);
    return model.copyWith(
      onTap: () {
        Get.toNamed(AppRoutes.productDetailsRoute, arguments: model);
      },
      onAddToCart: () {
        // Handled by widget/cart controller
      }
    );
  }

  void selectVariation(ProductVariation variation) {
    selectedVariation.value = variation;
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
        backgroundColor: const Color(0xFF14B8A6),
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
      backgroundColor: isFav ? const Color(0xFF14B8A6) : Colors.grey,
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
        backgroundColor: const Color(0xFF14B8A6),
        colorText: Colors.white,
      );
      return;
    }

    try {
      final cartController = Get.find<CartController>();
      final p = observableProduct.value;
      if (p == null) return;

      // If a variation is selected, construct a temporary ProductCardModel for the cart
      ProductCardModel productToAdd = p;
      if (p.hasVariations && selectedVariation.value != null) {
        final v = selectedVariation.value!;
        productToAdd = p.copyWith(
          id: '${p.id}_${v.id}',
          price: v.price,
          mrp: v.mrp,
          unit: v.unit,
          quantity: v.unitValue,
          image: v.image ?? p.image,
          inStock: v.inStock,
          stockCount: v.stockCount,
        );
      }

      // Use the centralized addToCart for strict stock enforcement
      bool added = cartController.addToCart(productToAdd, quantity.value);

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
      (selectedVariation.value?.price ?? observableProduct.value?.price ?? 0) * quantity.value;

  @override
  void onClose() {
    _cartPopupTimer?.cancel();
    _productSubscription?.cancel();
    super.onClose();
  }
}
