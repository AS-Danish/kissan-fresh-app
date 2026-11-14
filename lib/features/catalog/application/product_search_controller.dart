import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/features/cart/application/cart_controller.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/features/catalog/domain/section_model.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:kissanfresh/features/catalog/domain/product_card_model.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/core/utils/icon_utils.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';

import 'package:kissanfresh/core/services/cache_service.dart';

class ProductSearchController extends FeatureController {
  final Ref ref;

  ProductSearchController(
    this.ref, {
    this.initialCategory = 'All',
    this.startWithSpeech = false,
    this.section,
  }) : selectedCategory = Observable(initialCategory);

  final String initialCategory;
  final bool startWithSpeech;
  final SectionModel? section;
  late final HomepageController homepageController = ref.read(
    homepageControllerProvider,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CacheService _cacheService = ref.read(cacheServiceProvider);

  StreamSubscription? _catalogSubscription;
  ObservableList<ProductCardModel> searchCatalog = ObservableList(
    <ProductCardModel>[],
  );

  Observable<String> searchQuery = Observable('');
  final Observable<String> selectedCategory;
  late final FieldSubscription _queryWorker;
  late final FieldSubscription _categoryWorker;
  late final FieldSubscription _tabWorker;

  ObservableList<ProductCardModel> searchResults = ObservableList(
    <ProductCardModel>[],
  );
  Observable<bool> isLoading = Observable(false);
  int _searchToken = 0;

  // Pagination
  Observable<bool> isFetchingMore = Observable(false);
  Observable<bool> hasMoreProducts = Observable(true);
  DocumentSnapshot? _lastDocument;
  final int limit = 15;

  // Caching
  final Map<String, List<ProductCardModel>> _cache = {};

  // Speech to Text
  var speechToText = stt.SpeechToText();
  Observable<bool> isListening = Observable(false);
  Timer? _speechTimeoutTimer;

  // Recent Searches
  ObservableList<String> recentSearches = ObservableList(<String>[]);
  static const String recentSearchesKey = 'recent_searches_history';

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();

    // Setup debouncing for search query
    _queryWorker = observeField(searchQuery, (_) {
      if (!isClosed) _performSearch();
    }, delay: const Duration(milliseconds: 500));

    // Listen to category changes
    _categoryWorker = observeField(selectedCategory, (_) => _performSearch());
    _tabWorker = observeField(homepageController.currentTab, (_) {
      if (section != null) return;
      _listenToSearchCatalog();
      if (selectedCategory.value == 'All') {
        _performSearch();
      } else {
        selectedCategory.value = 'All';
      }
    });

    _listenToSearchCatalog();
    _initSpeech();
    _performSearch();

    // Automatically start listening if navigated here with arguments
    if (startWithSpeech) {
      // Small delay to allow transition before triggering mic popup
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isClosed) startListening();
      });
    }
  }

  void _listenToSearchCatalog() {
    _catalogSubscription?.cancel();

    final origin = _currentOrigin;
    final cacheKey = 'search_catalog_$origin';

    // 1. Instantly load from local Hive cache
    final cachedData = _cacheService.getProducts(cacheKey);
    if (cachedData.isNotEmpty) {
      searchCatalog.assignAll(cachedData);
      if (searchQuery.value.isNotEmpty) _performSearch();
    }

    // 2. Open real-time listener to keep the catalog fresh
    _catalogSubscription = _firestore
        .collection('products')
        .where('productOrigin', isEqualTo: origin)
        .limit(400)
        .snapshots()
        .listen(
          (snapshot) {
            final mapped = snapshot.docs
                .map((doc) => _mapToProductCardModel(doc))
                .toList();
            searchCatalog.assignAll(mapped);
            _cacheService.saveProducts(cacheKey, mapped);

            // Re-trigger active search to update UI if user is searching
            if (searchQuery.value.isNotEmpty) {
              _performSearch();
            }
          },
          onError: (e) {
            debugPrint("Error listening to search catalog: $e");
          },
        );
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

  Map<String, IconData> get categoryIcons {
    final isHomeFood = _currentOrigin == 'home-food';
    final sourceCategories = isHomeFood
        ? homepageController.homeFoodCategories
        : homepageController.categories;

    final icons = {
      for (final category in sourceCategories) category.label: category.icon,
    };
    final selected = selectedCategory.value;
    icons.putIfAbsent(selected, () => IconUtils.getCategoryIcon(selected));
    final initialIcon =
        icons.remove(initialCategory) ??
        (section == null ? null : IconUtils.getCategoryIcon(initialCategory));
    return {initialCategory: ?initialIcon, ...icons};
  }

  String get _currentOrigin =>
      section?.type ?? homepageController.currentOrigin;

  List<String> get _categoryFilter {
    if (section != null && selectedCategory.value == initialCategory) {
      return section!.categories.toSet().take(30).toList();
    }
    return selectedCategory.value == 'All'
        ? const []
        : [selectedCategory.value];
  }

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
      if (searchResults.isNotEmpty &&
          _lastDocument != null &&
          !hasMoreProducts.value) {
        _cache[cacheKey] = List.from(searchResults);
      }
      if (searchQuery.value.trim().isNotEmpty) {
        _saveRecentSearch(searchQuery.value);
      }
      isLoading.value = false;
    }
  }

  Future<void> fetchNextPage() async {
    if (isFetchingMore.value ||
        !hasMoreProducts.value ||
        _lastDocument == null) {
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
      final sq = searchQuery.value.trim().toLowerCase();

      if (sq.isNotEmpty) {
        // Search mode: Synchronous local filtering against the real-time cache
        if (token != _searchToken) return;

        final categoryFilter = _categoryFilter;
        final filtered = searchCatalog.where((p) {
          // If a category is selected, filter by it first
          if (categoryFilter.isNotEmpty &&
              !categoryFilter.contains(p.category)) {
            return false;
          }
          return _fuzzyMatch(sq, p.title);
        }).toList();

        searchResults.assignAll(filtered);
        hasMoreProducts.value = false;
      } else {
        // Browse mode: Standard pagination from Firestore
        Query query = _firestore
            .collection('products')
            .where('productOrigin', isEqualTo: _currentOrigin);

        final categoryFilter = _categoryFilter;
        if (categoryFilter.length == 1) {
          query = query.where('category', isEqualTo: categoryFilter.single);
        } else if (categoryFilter.isNotEmpty) {
          query = query.where('category', whereIn: categoryFilter);
        }
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        final snapshot = await query.limit(limit).get();
        if (token != _searchToken) return;

        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
          if (snapshot.docs.length < limit) {
            hasMoreProducts.value = false;
          }

          final mapped = snapshot.docs
              .map((doc) => _mapToProductCardModel(doc))
              .toList();
          searchResults.addAll(mapped);
        } else {
          hasMoreProducts.value = false;
        }
      }
    } catch (e) {
      debugPrint("Error in search fetch: $e");
      if (token == _searchToken) hasMoreProducts.value = false;
    }
  }

  ProductCardModel _mapToProductCardModel(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;

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

  bool _fuzzyMatch(String query, String target) {
    query = query.toLowerCase().trim();
    target = target.toLowerCase().trim();

    if (query.isEmpty) return true;
    if (target.contains(query) || query.contains(target)) return true;

    List<String> queryWords = query.split(RegExp(r'\s+'));
    List<String> targetWords = target.split(RegExp(r'\s+'));

    bool allWordsMatch = true;
    for (String qWord in queryWords) {
      if (qWord.isEmpty) continue;

      bool wordMatched = false;
      String qBase = qWord;
      if (qWord.length > 3) {
        if (qWord.endsWith('ies')) {
          qBase = '${qWord.substring(0, qWord.length - 3)}y';
        } else if (qWord.endsWith('es')) {
          qBase = qWord.substring(0, qWord.length - 2);
        } else if (qWord.endsWith('s')) {
          qBase = qWord.substring(0, qWord.length - 1);
        }
      }

      for (String tWord in targetWords) {
        if (tWord.isEmpty) continue;

        String tBase = tWord;
        if (tWord.length > 3) {
          if (tWord.endsWith('ies')) {
            tBase = '${tWord.substring(0, tWord.length - 3)}y';
          } else if (tWord.endsWith('es')) {
            tBase = tWord.substring(0, tWord.length - 2);
          } else if (tWord.endsWith('s')) {
            tBase = tWord.substring(0, tWord.length - 1);
          }
        }

        if (tWord == qWord ||
            tBase == qBase ||
            tWord.contains(qBase) ||
            qWord.contains(tBase)) {
          wordMatched = true;
          break;
        }
      }

      if (!wordMatched) {
        allWordsMatch = false;
        break;
      }
    }

    return allWordsMatch;
  }

  @override
  void onClose() {
    _searchToken++;
    _queryWorker.dispose();
    _categoryWorker.dispose();
    _tabWorker.dispose();
    _catalogSubscription?.cancel();
    _speechTimeoutTimer?.cancel();
    speechToText.stop();
    super.onClose();
  }
}

typedef SearchOptions = ({
  String category,
  bool startSpeech,
  SectionModel? section,
});

SearchOptions searchOptionsFor(Object? arguments) {
  final section = arguments is SectionModel ? arguments : null;
  final category = arguments is Map ? arguments['category'] : null;
  return (
    category: switch (section?.categories) {
      [final only] => only,
      [_, ...] => section!.name,
      _ => category is String && category.isNotEmpty ? category : 'All',
    },
    section: section,
    startSpeech: arguments is Map && arguments['startSpeech'] == true,
  );
}

final productSearchControllerProvider = Provider.autoDispose
    .family<ProductSearchController, SearchOptions>((ref, options) {
      return startController(
        ref,
        ProductSearchController(
          ref,
          initialCategory: options.category,
          section: options.section,
          startWithSpeech: options.startSpeech,
        ),
      );
    });
