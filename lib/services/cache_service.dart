import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/product_card_model.dart';

class CacheService extends GetxService {
  final Box _productsBox = Hive.box('products_cache');

  // Save regular products (by category/origin key)
  Future<void> saveProducts(String cacheKey, List<ProductCardModel> products) async {
    final data = products.map((p) => p.toJson()).toList();
    await _productsBox.put('products_$cacheKey', data);
  }

  // Get regular products
  List<ProductCardModel> getProducts(String cacheKey) {
    final data = _productsBox.get('products_$cacheKey');
    if (data != null && data is List) {
      return data.map((json) => ProductCardModel.fromJson(Map<String, dynamic>.from(json))).toList();
    }
    return [];
  }

  // Save categorized products for the Home/Categories screen
  Future<void> saveCategorizedProducts(String origin, Map<String, List<ProductCardModel>> categorizedData) async {
    final serializedData = categorizedData.map((key, value) {
      return MapEntry(key, value.map((p) => p.toJson()).toList());
    });
    await _productsBox.put('categorized_$origin', serializedData);
  }

  // Get categorized products
  Map<String, List<ProductCardModel>> getCategorizedProducts(String origin) {
    final data = _productsBox.get('categorized_$origin');
    if (data != null && data is Map) {
      return data.map((key, value) {
        final productList = (value as List).map((json) {
          return ProductCardModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
        return MapEntry(key.toString(), productList);
      });
    }
    return {};
  }

  // Generic save for any key-value pair
  Future<void> saveRaw(String key, dynamic value) async {
    await _productsBox.put(key, value);
  }

  // Generic get for any key
  dynamic getRaw(String key) {
    return _productsBox.get(key);
  }

  Future<void> clearCache() async {
    await _productsBox.clear();
  }
}
