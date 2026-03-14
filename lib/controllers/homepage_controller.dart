import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/views/screens/product_details_screen.dart';
import 'package:kissanfresh/model/product_card_model.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import '../model/category_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class HomepageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString currentTab = 'Grocery'.obs; // 'Grocery' or 'HomeFood'

  // Expose LocationService address
  RxnString get currentAddress => Get.find<LocationService>().currentAddress;

  // Today's Specials observables
  RxList<ProductCardModel> todaysSpecials = <ProductCardModel>[].obs;
  RxBool isLoadingSpecials = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box _cacheBox = Hive.box('user_settings'); // Reusing existing box or creating new one
  // Actually, implementation plan said 'cached_specials', let's use that if it exists or just user_settings if simpler.
  // Given user_settings is already used for theme, I'll use it for specials too to avoid needing more openBox calls in main.
  // Or I can open it here. Let's stick to the plan and open 'cached_specials'.

  @override
  void onInit() {
    super.onInit();
    _loadCachedSpecials();
    fetchTodaysSpecials();
  }

  void _loadCachedSpecials() {
    try {
      final cachedData = _cacheBox.get('todays_specials_cache');
      if (cachedData != null && cachedData is List) {
        todaysSpecials.value = cachedData.map((e) => ProductCardModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      debugPrint("Error loading cached specials: $e");
    }
  }

  Future<void> fetchTodaysSpecials() async {
    try {
      isLoadingSpecials.value = true;
      todaysSpecials.clear();

      // Get current date in yyyy-MM-dd format
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final docSnapshot = await _firestore.collection('todays_specials').doc(dateStr).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data['specials'] != null && data['specials'] is List) {
          final specialsList = data['specials'] as List;
          
          // Fetch all product details in parallel
          final List<Future<ProductCardModel?>> fetchPromises = specialsList.map((specialItem) async {
            if (specialItem is Map && specialItem['productId'] != null) {
              final productId = specialItem['productId'].toString();
              try {
                final productDoc = await _firestore.collection('products').doc(productId).get();
                if (productDoc.exists && productDoc.data() != null) {
                  final productData = productDoc.data()!;
                  
                  String imageUrl = '';
                  if (productData['image'] != null && productData['image'].toString().isNotEmpty) {
                    imageUrl = productData['image'];
                  } else if (productData['images'] != null && productData['images'] is List && productData['images'].isNotEmpty) {
                    imageUrl = productData['images'][0];
                  }

                  List<String>? imagesList;
                  if (productData['images'] != null && productData['images'] is List) {
                    imagesList = List<String>.from(productData['images']);
                  }

                  final inStock = productData['inStock'] ?? true;
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
                    onTap: () {
                      Get.to(() => ProductDetailsScreen(
                        product: ProductCardModel(
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
                          onTap: () {},
                          onAddToCart: () {},
                        ),
                      ));
                    },
                    onAddToCart: () {},
                  );
                }
              } catch (e) {
                debugPrint("Error fetching product details for $productId: $e");
              }
            }
            return null;
          }).toList();

          final List<ProductCardModel?> results = await Future.wait(fetchPromises);
          final List<ProductCardModel> fetchedSpecials = results.whereType<ProductCardModel>().toList();
          
          todaysSpecials.value = fetchedSpecials;
          
          // Save to cache
          final cacheData = fetchedSpecials.map((e) => e.toJson()).toList();
          await _cacheBox.put('todays_specials_cache', cacheData);
        }
      }
    } catch (e) {
      debugPrint("Error fetching today's specials: $e");
    } finally {
      isLoadingSpecials.value = false;
    }
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
    CategoryItemModel(
      label: "Pets",
      icon: FontAwesomeIcons.paw,
      onTap: () {},
    ),
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
      image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
      category: "Thali",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_1',
                title: "Spicy Paneer Thali",
                description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
                price: 150,
                unit: "plate",
                image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
                category: "Thali",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_1',
            title: "Spicy Paneer Thali",
            description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
            price: 150,
            unit: "plate",
            image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar("Added to Cart", "Spicy Paneer Thali added",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF0d9488),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 16,
              duration: const Duration(milliseconds: 1500));
        }
      },
    ),
    ProductCardModel(
      id: 'hf_2',
      title: "Chicken Biryani",
      description: "Aromatic basmati rice cooked with tender chicken and spices",
      price: 220,
      unit: "plate",
      image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Thali",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_2',
                title: "Chicken Biryani",
                description: "Aromatic basmati rice cooked with tender chicken and spices",
                price: 220,
                unit: "plate",
                image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Thali",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_2',
            title: "Chicken Biryani",
            description: "Aromatic basmati rice cooked with tender chicken and spices",
            price: 220,
            unit: "plate",
            image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar("Added to Cart", "Chicken Biryani added",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF0d9488),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 16,
              duration: const Duration(milliseconds: 1500));
        }
      },
    ),
    ProductCardModel(
      id: 'hf_3',
      title: "Methi Thepla",
      description: "Healthy and tasty flatbread made with fenugreek leaves",
      price: 40,
      unit: "pc",
      image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Snacks",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_3',
                title: "Methi Thepla",
                description: "Healthy and tasty flatbread made with fenugreek leaves",
                price: 40,
                unit: "pc",
                image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Snacks",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_3',
            title: "Methi Thepla",
            description: "Healthy and tasty flatbread made with fenugreek leaves",
            price: 40,
            unit: "pc",
            image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Snacks",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar("Added to Cart", "Methi Thepla added",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF0d9488),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 16,
              duration: const Duration(milliseconds: 1500));
        }
      },
    ),
    ProductCardModel(
      id: 'hf_4',
      title: "Gajar Ka Halwa",
      description: "Homemade carrot pudding made with ghee and milk",
      price: 300,
      unit: "500g",
      image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Sweets",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_4',
                title: "Gajar Ka Halwa",
                description: "Homemade carrot pudding made with ghee and milk",
                price: 300,
                unit: "500g",
                image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Sweets",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        bool added = Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_4',
            title: "Gajar Ka Halwa",
            description: "Homemade carrot pudding made with ghee and milk",
            price: 300,
            unit: "500g",
            image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Sweets",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        if (added) {
          Get.snackbar("Added to Cart", "Gajar Ka Halwa added",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF0d9488),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 16,
              duration: const Duration(milliseconds: 1500));
        }
      },
    ),
  ];
}