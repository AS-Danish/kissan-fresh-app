import 'package:kissanfresh/features/auth/application/auth_controller.dart';
import 'package:kissanfresh/features/cart/application/cart_controller.dart';
import 'package:kissanfresh/features/catalog/application/user_activity_controller.dart';
import 'package:kissanfresh/features/wishlist/application/wishlist_controller.dart';
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
import 'package:kissanfresh/features/cart/presentation/widgets/cart_success_popup.dart';

class ProductDetailsController extends FeatureController {
  final Ref ref;

  ProductDetailsController(this.ref);

  // Observable list for similar products
  var similarProducts = ObservableList(<ProductCardModel>[]);
  var isLoadingSimilarProducts = Observable(false);
  // Observable quantity
  var quantity = Observable(1);

  Timer? _cartPopupTimer;

  // Observable for current image index
  var currentImageIndex = Observable(0);

  void onImageChanged(int index) {
    currentImageIndex.value = index;
  }

  // Observable for selected variation
  var selectedVariation = Observable<ProductVariation?>(null);

  Observable<ProductCardModel?> observableProduct =
      Observable<ProductCardModel?>(null);
  StreamSubscription? _productSubscription;

  // Initialize with product passed as parameter
  void initializeProduct(ProductCardModel productData) {
    observableProduct.value = productData;

    if (productData.hasVariations &&
        productData.variations != null &&
        productData.variations!.isNotEmpty) {
      selectedVariation.value = productData.variations!.first;
    }

    // Universally track product view whenever product details are opened
    try {
      ref.read(userActivityControllerProvider).trackView(productData);
    } catch (e) {
      debugPrint("Error tracking product view: $e");
    }

    _startProductListener();
    _fetchSimilarProducts(productData);
    // Check if product is already in wishlist using safe ref.read
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
                if (data['quantity'] != null &&
                    data['quantity'].toString().isNotEmpty) {
                  prefix = data['quantity'].toString();
                } else if (data['weight'] != null &&
                    data['weight'].toString().isNotEmpty) {
                  prefix = data['weight'].toString();
                } else if (data['unitQuantity'] != null &&
                    data['unitQuantity'].toString().isNotEmpty) {
                  prefix = data['unitQuantity'].toString();
                } else if (data['unitValue'] != null &&
                    data['unitValue'].toString().isNotEmpty) {
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
              quantity:
                  data['quantity']?.toString() ??
                  data['weight']?.toString() ??
                  data['unitQuantity']?.toString() ??
                  data['unitValue']?.toString() ??
                  current.quantity,
              category: current.category,
              stockCount: (data['stockCount'] ?? 0).toInt(),
              inStock:
                  (data['inStock'] ?? true) && (data['stockCount'] ?? 0) > 0,
              tags: current.tags,
              hasVariations: data['hasVariations'] ?? false,
              variations: data['variations'] != null
                  ? (data['variations'] as List)
                        .map(
                          (v) => ProductVariation.fromJson(
                            Map<String, dynamic>.from(v),
                          ),
                        )
                        .toList()
                  : current.variations,
              onTap: current.onTap,
              onAddToCart: current.onAddToCart,
            );

            // Maintain selected variation
            if (observableProduct.value!.hasVariations &&
                observableProduct.value!.variations != null &&
                observableProduct.value!.variations!.isNotEmpty) {
              if (selectedVariation.value != null) {
                final existing = observableProduct.value!.variations!
                    .where(
                      (v) =>
                          (v.id != null &&
                              v.id == selectedVariation.value!.id) ||
                          (v.id == null &&
                              v.unit == selectedVariation.value!.unit &&
                              v.unitValue ==
                                  selectedVariation.value!.unitValue),
                    )
                    .firstOrNull;
                if (existing != null) {
                  selectedVariation.value = existing;
                } else {
                  selectedVariation.value =
                      observableProduct.value!.variations!.first;
                }
              } else {
                selectedVariation.value =
                    observableProduct.value!.variations!.first;
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
      if (productData.category != null &&
          productData.category!.isNotEmpty &&
          productData.category != 'All') {
        final query = FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: productData.category)
            .limit(11);
        final snapshot = await query.get();

        for (var doc in snapshot.docs) {
          if (doc.id == productData.id) continue; // Skip the current product

          final data = doc.data();
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

        if (productData.category != null &&
            productData.category!.isNotEmpty &&
            productData.category != 'All') {
          fallbackQuery = fallbackQuery.where(
            'category',
            isNotEqualTo: productData.category,
          );
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
        AppNavigator.toNamed(AppRoutes.productDetailsRoute, arguments: model);
      },
      onAddToCart: () {
        // Handled by widget/cart controller
      },
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
    final authController = ref.read(authControllerProvider);
    if (authController.firebaseUser.value == null) {
      AppNavigator.toNamed(AppRoutes.loginScreen);
      CustomSnackBar.show(
        'Login Required',
        'Please login to save favorite items across devices.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: AppNavigator.theme.primaryColor,
        colorText: Colors.white,
      );
      return;
    }

    final wishlistController = ref.read(wishlistControllerProvider);
    if (observableProduct.value != null) {
      wishlistController.toggleWishlist(observableProduct.value!);
    }

    final isFav =
        observableProduct.value != null &&
        wishlistController.isInWishlist(observableProduct.value!);

    CustomSnackBar.show(
      isFav ? 'Added to Favorites' : 'Removed from Favorites',
      isFav
          ? '${observableProduct.value?.title} added to your favorites'
          : '${observableProduct.value?.title} removed from favorites',
      snackPosition: SnackPosition.bottom,
      backgroundColor: isFav ? AppNavigator.theme.primaryColor : Colors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Add product to cart
  void addToCart() {
    final authController = ref.read(authControllerProvider);
    if (authController.firebaseUser.value == null) {
      AppNavigator.toNamed(AppRoutes.loginScreen);
      CustomSnackBar.show(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: AppNavigator.theme.primaryColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final cartController = ref.read(cartControllerProvider);
      final p = observableProduct.value;
      if (p == null) return;

      // If a variation is selected, construct a temporary ProductCardModel for the cart
      ProductCardModel productToAdd = p;
      if (p.hasVariations && selectedVariation.value != null) {
        final v = selectedVariation.value!;
        final vId = v.id ?? "${v.unitValue}${v.unit}";
        productToAdd = p.copyWith(
          id: '${p.id}_$vId',
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
        AppNavigator.dialog(const CartSuccessPopup(), barrierDismissible: true);

        // Automatically close after 2 seconds
        _cartPopupTimer?.cancel();
        _cartPopupTimer = Timer(const Duration(seconds: 2), () {
          if (AppNavigator.isDialogOpen) {
            AppNavigator.back();
          }
        });
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      CustomSnackBar.show(
        'Error',
        'Failed to add to cart',
        snackPosition: SnackPosition.bottom,
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
      (selectedVariation.value?.price ?? observableProduct.value?.price ?? 0) *
      quantity.value;

  @override
  void onClose() {
    _cartPopupTimer?.cancel();
    _productSubscription?.cancel();
    super.onClose();
  }
}

final productDetailsControllerProvider = Provider.autoDispose
    .family<ProductDetailsController, ProductCardModel>((ref, product) {
      final controller = startController(ref, ProductDetailsController(ref));
      controller.initializeProduct(product);
      return controller;
    });
