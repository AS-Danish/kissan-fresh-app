import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'homepage_controller.dart';
import 'cart_controller.dart';
import 'user_activity_controller.dart';

class ProductSearchController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxString searchQuery = ''.obs;
  RxString selectedCategory = 'All'.obs;

  RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  RxList<ProductCardModel> searchResults = <ProductCardModel>[].obs;
  RxBool isLoading = false.obs;
  int _searchToken = 0;

  // Pagination
  RxBool isFetchingMore = false.obs;
  RxBool hasMoreProducts = true.obs;
  DocumentSnapshot? _lastDocument;
  final int limit = 15;

  // Caching
  final Map<String, List<ProductCardModel>> _cache = {};

  // Speech to Text
  var speechToText = stt.SpeechToText();
  RxBool isListening = false.obs;
  Timer? _speechTimeoutTimer;

  // Recent Searches
  RxList<String> recentSearches = <String>[].obs;
  static const String recentSearchesKey = 'recent_searches_history';

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _setCategories();

    if (Get.arguments != null && Get.arguments['category'] != null) {
      selectedCategory.value = Get.arguments['category'];
    }

    // Setup debouncing for search query
    debounce(
      searchQuery,
      (_) => _performSearch(),
      time: const Duration(milliseconds: 500),
    );

    // Listen to category changes
    ever(selectedCategory, (_) => _performSearch());
    ever(homepageController.currentTab, (_) {
      _setCategories();
      selectedCategory.value = 'All'; // Will trigger search
    });

    _initSpeech();
    _performSearch();

    // Automatically start listening if navigated here with arguments
    if (Get.arguments?['startSpeech'] == true) {
      // Small delay to allow transition before triggering mic popup
      Future.delayed(const Duration(milliseconds: 300), startListening);
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(recentSearchesKey) ?? [];
    recentSearches.assignAll(searches);
  }

  Future<void> _saveRecentSearch(String query) async {
    String trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(recentSearchesKey) ?? [];

    searches.remove(trimmed);
    searches.insert(0, trimmed);
    if (searches.length > 5) {
      searches = searches.sublist(0, 5);
    }

    await prefs.setStringList(recentSearchesKey, searches);
    recentSearches.assignAll(searches);
  }

  Future<void> removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(recentSearchesKey) ?? [];
    searches.remove(query);
    await prefs.setStringList(recentSearchesKey, searches);
    recentSearches.assignAll(searches);
  }

  void _initSpeech() async {
    try {
      bool available = await speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
        onError: (error) {
          isListening.value = false;
          debugPrint('Speech error: $error');
        },
      );
      if (!available) {
        debugPrint("Speech recognition not available");
      }
    } catch (e) {
      debugPrint("Speech init exception: $e");
    }
  }

  void startListening() async {
    if (!isListening.value) {
      bool available = await speechToText.initialize();
      if (available) {
        isListening.value = true;

        // Start 3-second timeout timer
        _speechTimeoutTimer?.cancel();
        _speechTimeoutTimer = Timer(const Duration(seconds: 3), () {
          if (isListening.value && searchQuery.value.isEmpty) {
            stopListening();
          }
        });

        speechToText.listen(
          onResult: (result) {
            // Cancel timeout once we get some words
            _speechTimeoutTimer?.cancel();

            searchQuery.value = result.recognizedWords;
          },
          localeId: 'en_IN',
        );
      }
    }
  }

  void stopListening() async {
    _speechTimeoutTimer?.cancel();
    await speechToText.stop();
    isListening.value = false;
  }

  // Required since search_screen uses filteredProducts
  List<ProductCardModel> get filteredProducts => searchResults.toList();

  void _setCategories() {
    final isHomeFood = homepageController.currentTab.value == 'HomeFood';
    final sourceCategories = isHomeFood
        ? homepageController.homeFoodCategories
        : homepageController.categories;

    categories.assignAll(
      sourceCategories
          .map(
            (c) => {
              'name': c.label,
              'icon': c.icon,
              'color': const Color(0xFF0d9488),
            },
          )
          .toList(),
    );
  }

  String get _currentOrigin => homepageController.currentTab.value == 'Grocery'
      ? 'kissan-fresh'
      : 'home-food';

  String _getCacheKey() {
    return '${_currentOrigin}_${selectedCategory.value}_${searchQuery.value.trim().toLowerCase()}';
  }

  void _performSearch() async {
    final int currentToken = ++_searchToken;
    final cacheKey = _getCacheKey();

    if (_cache.containsKey(cacheKey)) {
      searchResults.assignAll(_cache[cacheKey]!);
      hasMoreProducts.value = false; // Simplified caching
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _lastDocument = null;
    hasMoreProducts.value = true;

    // Only clear if we are starting a fresh search matching the current token
    if (currentToken == _searchToken) {
      searchResults.clear();
    }

    await _fetchData(currentToken);

    if (currentToken == _searchToken) {
      if (searchResults.isNotEmpty && _lastDocument != null) {
        _cache[cacheKey] = List.from(searchResults);
      }
      if (searchQuery.value.trim().isNotEmpty) {
        _saveRecentSearch(searchQuery.value);
      }
      isLoading.value = false;
    }
  }

  Future<void> fetchNextPage() async {
    if (isFetchingMore.value || !hasMoreProducts.value || _lastDocument == null) {
      return;
    }

    isFetchingMore.value = true;
    await _fetchData(_searchToken);

    // Check if the search wasn't cancelled while we fetched
    if (isFetchingMore.value) {
      isFetchingMore.value = false;
    }
  }

  Future<void> _fetchData(int token) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('productOrigin', isEqualTo: _currentOrigin);

      if (selectedCategory.value != 'All') {
        query = query.where('category', isEqualTo: selectedCategory.value);
      }

      final sq = searchQuery.value.trim();
      if (sq.isNotEmpty) {
        String prefix = sq;
        if (sq.length > 1) {
          prefix = sq[0].toUpperCase() + sq.substring(1).toLowerCase();
        } else {
          prefix = sq.toUpperCase();
        }

        query = query
            .where('name', isGreaterThanOrEqualTo: prefix)
            .where('name', isLessThan: '$prefix\u{f8ff}');
      }

      query = query.limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (token != _searchToken) return;

      if (snapshot.docs.isEmpty) {
        hasMoreProducts.value = false;
        return;
      }

      _lastDocument = snapshot.docs.last;

      final mappedProducts = snapshot.docs
          .map((doc) => _mapToProductCardModel(doc))
          .toList();
      searchResults.addAll(mappedProducts);

      if (snapshot.docs.length < limit) {
        hasMoreProducts.value = false;
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      if (token == _searchToken) {
        hasMoreProducts.value = false;
      }
    }
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String imageUrl = '';
    if (data['image'] != null && data['image'].toString().isNotEmpty) {
      imageUrl = data['image'];
    } else if (data['images'] != null &&
        data['images'] is List &&
        data['images'].isNotEmpty) {
      imageUrl = data['images'][0];
    }

    List<String>? imagesList;
    if (data['images'] != null && data['images'] is List) {
      imagesList = List<String>.from(data['images']);
    }

    final stockCount = (data['stockCount'] ?? 0).toInt();
    final inStock = (data['inStock'] ?? true) && stockCount > 0;
    final category = data['category'] ?? 'General';

    List<String> dynamicTags = [];
    if (data['tags'] != null && data['tags'] is List) {
      dynamicTags = List<String>.from(data['tags']);
    }

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
      stockCount: stockCount,
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
        stockCount: stockCount,
      ),
      onAddToCart: () {
        try {
          final cartController = Get.find<CartController>();
          final productModel = _mapToProductCardModel(doc);
          bool added = cartController.addToCart(productModel, 1);
          if (added) {
            Get.snackbar(
              'Added to Cart',
              '${data['name'] ?? 'Product'} added to cart',
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
    int stockCount = 0,
  }) {
    try {
      Get.find<UserActivityController>().trackView(
        ProductCardModel(
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
          stockCount: stockCount,
          onTap: () {},
          onAddToCart: () {},
        ),
      );
    } catch (e) {
      debugPrint("UserActivityController tracking error: $e");
    }

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
        stockCount: stockCount,
        onTap: () {},
        onAddToCart: () {},
      ),
    );
  }

  @override
  void onClose() {
    _speechTimeoutTimer?.cancel();
    speechToText.stop();
    super.onClose();
  }
}
