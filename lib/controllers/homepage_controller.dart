import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/views/screens/product_details_screen.dart';
import 'package:kissanfresh/model/product_card_model.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import '../model/category_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';

class HomepageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString currentTab = 'Grocery'.obs; // 'Grocery' or 'HomeFood'

  // Expose LocationService address
  RxnString get currentAddress => Get.find<LocationService>().currentAddress;

  // Today's Specials observables
  RxList<ProductCardModel> todaysSpecials = <ProductCardModel>[].obs;
  final RxBool isLoadingSpecials = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = Get.find<CacheService>();

  @override
  void onInit() {
    super.onInit();
    _loadCachedSpecials();
    fetchTodaysSpecials();
  }

  void _loadCachedSpecials() {
    try {
      final cachedData = _cacheService.getRaw('todays_specials_cache');
      if (cachedData != null && cachedData is List) {
        todaysSpecials.assignAll(
          cachedData
              .map(
                (e) => ProductCardModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
        );
      }
    } catch (e) {
      debugPrint("Error loading cached specials: $e");
    }
  }

  void fetchTodaysSpecials() {
    try {
      isLoadingSpecials.value = true;

      // Get current date string
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Use a listener for the specials document itself
      _firestore
          .collection('todays_specials')
          .doc(dateStr)
          .snapshots()
          .listen(
            (docSnapshot) async {
              if (docSnapshot.exists && docSnapshot.data() != null) {
                final data = docSnapshot.data()!;
                if (data['specials'] != null && data['specials'] is List) {
                  final specialsList = data['specials'] as List;

                  // For each special, we want real-time stock updates too.
                  // However, nested listeners can be complex.
                  // We'll fetch them all and refresh whenever the specials list changes.
                  // Collect all product IDs
                  final List<String> productIds = [];
                  for (var specialItem in specialsList) {
                    if (specialItem is Map &&
                        specialItem['productId'] != null) {
                      productIds.add(specialItem['productId'].toString());
                    }
                  }

                  final List<ProductCardModel> fetchedSpecials = [];

                  if (productIds.isNotEmpty) {
                    try {
                      // Limit to 30 for whereIn clause. In realistic scenarios, specials are < 30.
                      final limitedIds = productIds.take(30).toList();
                      final productsSnapshot = await _firestore
                          .collection('products')
                          .where(FieldPath.documentId, whereIn: limitedIds)
                          .get();

                      for (var doc in productsSnapshot.docs) {
                        fetchedSpecials.add(_mapDocToModel(doc));
                      }

                      // Keep the original order sorted from specialsList
                      fetchedSpecials.sort((a, b) {
                        final indexA = productIds.indexOf(a.id!);
                        final indexB = productIds.indexOf(b.id!);
                        return indexA.compareTo(indexB);
                      });
                    } catch (e) {
                      debugPrint(
                        "Error fetching batched products for specials: $e",
                      );
                    }
                  }

                  todaysSpecials.assignAll(fetchedSpecials);

                  // Save to cache
                  final cacheData = fetchedSpecials
                      .map((e) => e.toJson())
                      .toList();
                  _cacheService.saveRaw('todays_specials_cache', cacheData);
                }
              }
              isLoadingSpecials.value = false;
            },
            onError: (e) {
              debugPrint("Error in specials stream: $e");
              isLoadingSpecials.value = false;
            },
          );
    } catch (e) {
      debugPrint("Error setting up today's specials stream: $e");
      isLoadingSpecials.value = false;
    }
  }

  ProductCardModel _mapDocToModel(DocumentSnapshot productDoc) {
    final productData = productDoc.data() as Map<String, dynamic>;

    String imageUrl = '';
    if (productData['image'] != null &&
        productData['image'].toString().isNotEmpty) {
      imageUrl = productData['image'];
    } else if (productData['images'] != null &&
        productData['images'] is List &&
        productData['images'].isNotEmpty) {
      imageUrl = productData['images'][0];
    }

    List<String>? imagesList;
    if (productData['images'] != null && productData['images'] is List) {
      imagesList = List<String>.from(productData['images']);
    }

    final stockCount = (productData['stockCount'] ?? 0).toInt();
    final inStock = (productData['inStock'] ?? true) && stockCount > 0;
    final category = productData['category'] ?? 'General';

    List<String> dynamicTags = [];
    if (productData['tags'] != null && productData['tags'] is List) {
      dynamicTags = List<String>.from(productData['tags']);
    }

    return ProductCardModel(
      id: productDoc.id,
      image: imageUrl,
      images: imagesList,
      title: productData['name'] ?? 'Unknown',
      description: productData['description'] ?? '',
      price: (productData['price'] ?? 0).toDouble(),
      unit: productData['unit'] ?? 'unit',
      category: category,
      tags: dynamicTags.isNotEmpty ? dynamicTags : null,
      inStock: inStock,
      stockCount: stockCount,
      onTap: () {
        Get.to(
          () => ProductDetailsScreen(
            product: _mapDocToModel(productDoc), // Re-map to ensure fresh data
          ),
        );
      },
      onAddToCart: () {
        try {
          final cartController = Get.find<CartController>();
          final productModel = _mapDocToModel(productDoc);
          bool added = cartController.addToCart(productModel, 1);
          if (added) {
            Get.snackbar(
              'Added to Cart',
              '${productData['name'] ?? 'Product'} added to cart',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF10B981),
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

  void switchTab(String tab) {
    currentTab.value = tab;
  }

  void updateAddress(String newAddress) {
    Get.find<LocationService>().currentAddress.value = newAddress;
  }

  final categories = [
    CategoryItemModel(
      label: "All",
      icon: FontAwesomeIcons.tableCells,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Winter",
      icon: FontAwesomeIcons.snowflake,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Electronics",
      icon: FontAwesomeIcons.desktop,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Beauty",
      icon: FontAwesomeIcons.spa,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Groceries",
      icon: FontAwesomeIcons.basketShopping,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fashion",
      icon: FontAwesomeIcons.shirt,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Footwear",
      icon: FontAwesomeIcons.shoePrints,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Home",
      icon: FontAwesomeIcons.couch,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Kitchen",
      icon: FontAwesomeIcons.utensils,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fitness",
      icon: FontAwesomeIcons.dumbbell,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Books",
      icon: FontAwesomeIcons.book,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Toys",
      icon: FontAwesomeIcons.puzzlePiece,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gaming",
      icon: FontAwesomeIcons.gamepad,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Music",
      icon: FontAwesomeIcons.music,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Travel",
      icon: FontAwesomeIcons.suitcaseRolling,
      onTap: () {},
    ),
    CategoryItemModel(label: "Pets", icon: FontAwesomeIcons.paw, onTap: () {}),
    CategoryItemModel(
      label: "Pharmacy",
      icon: FontAwesomeIcons.pills,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gifts",
      icon: FontAwesomeIcons.gift,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gifts",
      icon: FontAwesomeIcons.gift,
      onTap: () {},
    ),
  ];

  final homeFoodCategories = [
    CategoryItemModel(
      label: "All",
      icon: FontAwesomeIcons.utensils,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Tiffins",
      icon: FontAwesomeIcons.boxOpen,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Thali",
      icon: FontAwesomeIcons.plateWheat,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Snacks",
      icon: FontAwesomeIcons.cookieBite,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Sweets",
      icon: FontAwesomeIcons.candyCane,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Pickles",
      icon: FontAwesomeIcons.jar,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Spices",
      icon: FontAwesomeIcons.pepperHot,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Bakery",
      icon: FontAwesomeIcons.breadSlice,
      onTap: () {},
    ),
  ];

  RxInt selectedHomeFoodIndex = 0.obs;

  void selectHomeFoodCategory(int index) {
    selectedHomeFoodIndex.value = index;
  }

  void selectCategory(int index) {
    selectedIndex.value = index;
  }

  // Home Food Products
  final homeFoodProducts = [
    ProductCardModel(
      id: 'hf_1',
      title: "Spicy Paneer Thali",
      description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
      price: 150,
      unit: "plate",
      image:
          "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
      category: "Thali",
      onTap: () {
        Get.to(
          () => ProductDetailsScreen(
            product: ProductCardModel(
              id: 'hf_1',
              title: "Spicy Paneer Thali",
              description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
              price: 150,
              unit: "plate",
              image:
                  "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
              category: "Thali",
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        );
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_1',
            title: "Spicy Paneer Thali",
            description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
            price: 150,
            unit: "plate",
            image:
                "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar(
            "Added to Cart",
            "Spicy Paneer Thali added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500),
          );
        }
      },
    ),
    ProductCardModel(
      id: 'hf_2',
      title: "Chicken Biryani",
      description:
          "Aromatic basmati rice cooked with tender chicken and spices",
      price: 220,
      unit: "plate",
      image:
          "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Thali",
      onTap: () {
        Get.to(
          () => ProductDetailsScreen(
            product: ProductCardModel(
              id: 'hf_2',
              title: "Chicken Biryani",
              description:
                  "Aromatic basmati rice cooked with tender chicken and spices",
              price: 220,
              unit: "plate",
              image:
                  "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
              category: "Thali",
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        );
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_2',
            title: "Chicken Biryani",
            description:
                "Aromatic basmati rice cooked with tender chicken and spices",
            price: 220,
            unit: "plate",
            image:
                "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar(
            "Added to Cart",
            "Chicken Biryani added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500),
          );
        }
      },
    ),
    ProductCardModel(
      id: 'hf_3',
      title: "Methi Thepla",
      description: "Healthy and tasty flatbread made with fenugreek leaves",
      price: 40,
      unit: "pc",
      image:
          "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Snacks",
      onTap: () {
        Get.to(
          () => ProductDetailsScreen(
            product: ProductCardModel(
              id: 'hf_3',
              title: "Methi Thepla",
              description:
                  "Healthy and tasty flatbread made with fenugreek leaves",
              price: 40,
              unit: "pc",
              image:
                  "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
              category: "Snacks",
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        );
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_3',
            title: "Methi Thepla",
            description:
                "Healthy and tasty flatbread made with fenugreek leaves",
            price: 40,
            unit: "pc",
            image:
                "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Snacks",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar(
            "Added to Cart",
            "Methi Thepla added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500),
          );
        }
      },
    ),
    ProductCardModel(
      id: 'hf_4',
      title: "Gajar Ka Halwa",
      description: "Homemade carrot pudding made with ghee and milk",
      price: 300,
      unit: "500g",
      image:
          "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Sweets",
      onTap: () {
        Get.to(
          () => ProductDetailsScreen(
            product: ProductCardModel(
              id: 'hf_4',
              title: "Gajar Ka Halwa",
              description: "Homemade carrot pudding made with ghee and milk",
              price: 300,
              unit: "500g",
              image:
                  "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
              category: "Sweets",
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        );
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_4',
            title: "Gajar Ka Halwa",
            description: "Homemade carrot pudding made with ghee and milk",
            price: 300,
            unit: "500g",
            image:
                "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Sweets",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar(
            "Added to Cart",
            "Gajar Ka Halwa added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500),
          );
        }
      },
    ),
  ];
}
