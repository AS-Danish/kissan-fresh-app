import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/views/screens/product_details_screen.dart';
import 'package:kissanfresh/model/product_card_model.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import '../model/category_item_model.dart';
import '../model/coupon_model.dart';
import '../model/section_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cache_service.dart';
import '../utils/icon_utils.dart';
import 'user_activity_controller.dart';

class HomepageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString currentTab = 'Grocery'.obs; // 'Grocery' or 'HomeFood'

  String get currentOrigin => currentTab.value == 'Grocery' ? 'kissan-fresh' : 'home-food';

  // Expose LocationService address
  RxnString get currentAddress => Get.find<LocationService>().currentAddress;

  // Today's Specials observables
  RxList<ProductCardModel> todaysSpecials = <ProductCardModel>[].obs;
  final RxBool isLoadingSpecials = false.obs;

  // Sections observables
  RxList<SectionModel> sections = <SectionModel>[].obs;
  RxMap<String, List<ProductCardModel>> sectionProducts = <String, List<ProductCardModel>>{}.obs;
  final RxBool isLoadingSections = false.obs;

  // Active Coupons observables
  final RxList<CouponModel> activeCoupons = <CouponModel>[].obs;
  final RxBool isLoadingCoupons = false.obs;

  final CacheService _cacheService = Get.find<CacheService>();
  StreamSubscription? _specialsSubscription;
  StreamSubscription? _sectionsSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void>? categoriesFuture;

  @override
  void onInit() {
    super.onInit();
    _loadCachedSpecials();
    fetchTodaysSpecials();
    categoriesFuture = fetchCategories();
    _setupSectionsListener();
    fetchActiveCoupons();
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
      _specialsSubscription = _firestore
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
      mrp: productData['mrp'] != null ? (productData['mrp'] as num).toDouble() : null,
      unit: productData['unit'] ?? 'unit',
      category: category,
      tags: dynamicTags.isNotEmpty ? dynamicTags : null,
      inStock: inStock,
      stockCount: stockCount,
      onTap: () {
        final product = _mapDocToModel(productDoc);
        try {
          Get.find<UserActivityController>().trackView(product);
        } catch (e) {
          debugPrint("UserActivityController error: $e");
        }
        Get.to(
          () => ProductDetailsScreen(
            product: product, // Re-map to ensure fresh data
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

  // Reactive categories
  late RxList<CategoryItemModel> categories;
  late RxList<CategoryItemModel> homeFoodCategories;

  HomepageController() {
    // Initialize with "All" to prevent RangeError in UI before first fetch
    categories = <CategoryItemModel>[
      CategoryItemModel(
        label: "All",
        icon: Icons.grid_view,
        onTap: () {},
      ),
    ].obs;

    homeFoodCategories = <CategoryItemModel>[
      CategoryItemModel(
        label: "All",
        icon: Icons.restaurant,
        onTap: () {},
      ),
    ].obs;
  }

  Future<void> fetchCategories() async {
    // 1. Fetch Grocery (kissan-fresh)
    await _fetchAndMapCategories('kissan-fresh', categories, 'Grocery');
    // 2. Fetch Home Food (home-food)
    await _fetchAndMapCategories('home-food', homeFoodCategories, 'HomeFood');
  }

  Future<void> _fetchAndMapCategories(
    String type,
    RxList<CategoryItemModel> targetList,
    String tabName,
  ) async {
    final cacheKey = 'categories_$type';
    final timestampKey = '${cacheKey}_timestamp';

    try {
      // 1. Check Cache
      final cachedJson = _cacheService.getRaw(cacheKey);
      final cachedTimeStr = _cacheService.getRaw(timestampKey);

      bool shouldUseCache = false;
      if (cachedJson != null && cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr.toString());
        if (DateTime.now().difference(cachedTime).inMinutes < 2) {
          shouldUseCache = true;
        }
      }

      if (shouldUseCache) {
        debugPrint("Loading categories for $type from local cache (within 2 min)");
        _mapJsonToCategories(cachedJson, targetList, tabName);
        return;
      }

      // 2. Fetch from Firestore
      debugPrint("Fetching categories for $type from Firestore...");
      final snapshot = await _firestore
          .collection('categories')
          .where('type', isEqualTo: type)
          .orderBy('name')
          .limit(50)
          .get();

      final dataList = snapshot.docs.map((doc) => _sanitizeFirestoreData(doc.data())).toList();

      // 3. Save to Cache
      await _cacheService.saveRaw(cacheKey, dataList);
      await _cacheService.saveRaw(
        timestampKey,
        DateTime.now().toIso8601String(),
      );

      // 4. Update UI
      _mapJsonToCategories(dataList, targetList, tabName);
    } catch (e) {
      debugPrint("Error fetching categories for $type: $e");
      // Fallback to cache if Firestore fails even if expired
      final cachedJson = _cacheService.getRaw(cacheKey);
      if (cachedJson != null) {
        _mapJsonToCategories(cachedJson, targetList, tabName);
      }
    }
  }

  void _mapJsonToCategories(
    dynamic json,
    RxList<CategoryItemModel> targetList,
    String tabName,
  ) {
    if (json is! List) return;

    final List<CategoryItemModel> items = [];

    // Always prepend "All"
    items.add(
      CategoryItemModel(
        label: "All",
        icon: tabName == 'Grocery' ? Icons.grid_view : Icons.restaurant,
        onTap: () {},
      ),
    );

    for (var entry in json) {
      if (entry is Map) {
        final name = entry['name']?.toString() ?? 'Unknown';
        items.add(
          CategoryItemModel(
            label: name,
            icon: IconUtils.getCategoryIcon(name),
            onTap: () {},
          ),
        );
      }
    }

    targetList.assignAll(items);
  }

  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> sanitized = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeFirestoreData(value);
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is Map<String, dynamic>) return _sanitizeFirestoreData(e);
          if (e is Timestamp) return e.toDate().toIso8601String();
          return e;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  void _setupSectionsListener() {
    _sectionsSubscription?.cancel();
    isLoadingSections.value = true;

    // We fetch all sections but we'll filter in the UI by type
    // This allows smooth tab switching without re-fetching
    _sectionsSubscription = _firestore
        .collection('sections')
        .orderBy('rank')
        .snapshots()
        .listen((snapshot) {
      final fetchedSections = snapshot.docs
          .map((doc) => SectionModel.fromJson(doc.data(), doc.id))
          .toList();
      
      sections.assignAll(fetchedSections);

      // Fetch products for each section if not already fetching
      for (var section in fetchedSections) {
        if (section.categories.isNotEmpty) {
          _fetchProductsForSection(section);
        }
      }
      isLoadingSections.value = false;
    }, onError: (e) {
      debugPrint("Error in sections listener: $e");
      isLoadingSections.value = false;
    });
  }

  // Deprecated - kept for compatibility if called elsewhere temporarily
  Future<void> fetchSections() async {
    _setupSectionsListener();
  }

  Future<void> fetchActiveCoupons() async {
    try {
      isLoadingCoupons.value = true;
      final snapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      final fetchedCoupons = snapshot.docs
          .map((doc) => CouponModel.fromJson(doc.data()))
          .toList();

      activeCoupons.assignAll(fetchedCoupons);
    } catch (e) {
      debugPrint("Error fetching active coupons: $e");
    } finally {
      isLoadingCoupons.value = false;
    }
  }

  Future<void> _fetchProductsForSection(SectionModel section) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', whereIn: section.categories.take(10).toList()) // whereIn limit is 10
          .limit(4) // Only need up to 4 for the 2x2 layout
          .get();
      
      final products = snapshot.docs.map(_mapDocToModel).toList();
      sectionProducts[section.id] = products;
    } catch (e) {
      debugPrint("Error fetching products for section ${section.name}: $e");
    }
  }

  // REMOVED: Static final lists replaced by RxLists above.

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
  @override
  void onClose() {
    _specialsSubscription?.cancel();
    super.onClose();
  }
}
