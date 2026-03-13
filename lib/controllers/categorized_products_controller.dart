import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'homepage_controller.dart';

class CategorizedProductsController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map of category name to list of products
  final RxMap<String, List<ProductCardModel>> categorizedProducts = <String, List<ProductCardModel>>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab changes to fetch categorized products for the correct origin
    ever(homepageController.currentTab, (_) {
      fetchCategorizedProducts();
    });
    fetchCategorizedProducts();
  }

  String get currentOrigin {
    return homepageController.currentTab.value == 'Grocery' ? 'kissan-fresh' : 'home-food';
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
      isLoading.value = true;
      categorizedProducts.clear();

      final categoriesList = currentCategories;
      final origin = currentOrigin;

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
          .limit(6) // limit to 6 products per category for the horizontal scroll
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<ProductCardModel> products = querySnapshot.docs.map((doc) => _mapToProductCardModel(doc)).toList();
        categorizedProducts[category] = products;
      }
    } catch (e) {
      debugPrint("Error fetching category $category: $e");
    }
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract a single image logic
    String imageUrl = '';
    if (data['image'] != null && data['image'].toString().isNotEmpty) {
      imageUrl = data['image'];
    } else if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
      imageUrl = data['images'][0];
    }
    
    // Parse list of images if any
    List<String>? imagesList;
    if (data['images'] != null && data['images'] is List) {
      imagesList = List<String>.from(data['images']);
    }

    final inStock = data['inStock'] ?? true;
    final category = data['category'] ?? 'General';

    // Parse existing tags from db if any
    List<String> dynamicTags = [];
    if (data['tags'] != null && data['tags'] is List) {
      dynamicTags = List<String>.from(data['tags']);
    }
    
    // Add implicit tags
    if (category != 'General' && !dynamicTags.contains(category)) {
      dynamicTags.add(category);
    }
    if (inStock && !dynamicTags.contains('In Stock')) {
      dynamicTags.add('In Stock');
    }

    return ProductCardModel(
      id: doc.id,
      image: imageUrl,
      images: imagesList,
      title: data['title'] ?? 'Unknown',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'unit',
      category: category,
      tags: dynamicTags.isNotEmpty ? dynamicTags : null,
      inStock: inStock,
      onTap: () => _navigateToProductDetails(
        id: doc.id,
        image: imageUrl,
        images: imagesList,
        title: data['title'] ?? 'Unknown',
        description: data['description'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        unit: data['unit'] ?? 'unit',
        category: category,
        tags: dynamicTags.isNotEmpty ? dynamicTags : null,
        inStock: inStock,
      ),
      onAddToCart: () {
        debugPrint('Adding ${data['title']} to cart');
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
    required String unit,
    String? category,
    List<String>? tags,
    bool inStock = true,
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
        unit: unit,
        category: category,
        tags: tags,
        inStock: inStock,
        onTap: () {},
        onAddToCart: () {},
      ),
    );
  }
}
