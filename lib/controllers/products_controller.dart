import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'homepage_controller.dart';

class ProductsController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final RxList<ProductCardModel> products = <ProductCardModel>[].obs;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time stream subscription for caching
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // Cache to store products per tab origin to avoid re-fetching on tab switch
  final Map<String, List<ProductCardModel>> _cachedProducts = {
    'kissan-fresh': [],
    'home-food': [],
  };

  // Pagination observables
  RxBool isLoadingProducts = false.obs;
  RxBool isFetchingMore = false.obs;
  RxBool hasMoreProducts = true.obs;
  
  // Variables to hold the last document for each tab for pagination
  final Map<String, DocumentSnapshot?> _lastDocuments = {
    'kissan-fresh': null,
    'home-food': null,
  };
  
  final int limit = 10;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab changes
    ever(homepageController.currentTab, (_) {
      fetchInitialProducts();
    });
    fetchInitialProducts();
  }

  String get currentOrigin {
    return homepageController.currentTab.value == 'Grocery' ? 'kissan-fresh' : 'home-food';
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchInitialProducts() async {
    final origin = currentOrigin;

    // Load from cache instantly if available to prevent loading spinners
    if (_cachedProducts[origin]!.isNotEmpty) {
      products.value = _cachedProducts[origin]!;
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
      _productsSubscription = _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin)
          .limit(limit)
          .snapshots(includeMetadataChanges: true) // Allows observing cache vs server states
          .listen((QuerySnapshot snapshot) {
            
        if (snapshot.docs.isEmpty) {
          hasMoreProducts.value = false;
          products.value = [];
          _cachedProducts[origin] = [];
          isLoadingProducts.value = false;
          return;
        }

        // Store the last document of the initial load for pagination
        _lastDocuments[origin] = snapshot.docs.last;
        
        final mappedProducts = snapshot.docs.map((doc) => _mapToProductCardModel(doc)).toList();
        
        // Only update if there's actually new or changed data. Stream triggers on initial load as well.
        products.value = mappedProducts;
        _cachedProducts[origin] = mappedProducts;

        if (snapshot.docs.length < limit) {
          hasMoreProducts.value = false;
        } else {
          hasMoreProducts.value = true;
        }
        
        isLoadingProducts.value = false;
      }, onError: (error) {
        debugPrint("Error in products stream: $error");
        isLoadingProducts.value = false;
      });

    } catch (e) {
      debugPrint("Error setting up initial products stream: $e");
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchNextPage() async {
    final origin = currentOrigin;
    final lastDoc = _lastDocuments[origin];

    if (isFetchingMore.value || !hasMoreProducts.value || lastDoc == null) return;

    try {
      isFetchingMore.value = true;

      // Use a one-time get() for pagination to avoid compounding streams
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: origin)
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        hasMoreProducts.value = false;
        return;
      }

      _lastDocuments[origin] = querySnapshot.docs.last;
      
      final newProducts = querySnapshot.docs.map((doc) => _mapToProductCardModel(doc)).toList();
      
      products.addAll(newProducts);
      _cachedProducts[origin]!.addAll(newProducts); // Update cache with paginated data

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
    
    // Extract a single image logic
    String imageUrl = '';
    if (data['image'] != null && data['image'].toString().isNotEmpty) {
      imageUrl = data['image'];
    } else if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
      imageUrl = data['images'][0];
    }
    
    // Parse list of images if any (optional based on your model)
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
      title: data['name'] ?? 'Unknown',
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
        title: data['name'] ?? 'Unknown',
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

  // Helper method for navigation using named routes
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
