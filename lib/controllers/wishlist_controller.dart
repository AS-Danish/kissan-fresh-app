import 'package:get/get.dart';
import '../model/product_card_model.dart';

class WishlistController extends GetxController {
  // Observable list of wishlist items
  RxList<ProductCardModel> wishlistItems = <ProductCardModel>[].obs;

  // Add item to wishlist
  void addToWishlist(ProductCardModel product) {
    if (!isInWishlist(product)) {
      wishlistItems.add(product);
    }
  }

  // Remove item from wishlist
  void removeFromWishlist(ProductCardModel product) {
    // Remove by ID if available, otherwise by title
    if (product.id != null) {
      wishlistItems.removeWhere((item) => item.id == product.id);
    } else {
      wishlistItems.removeWhere((item) => item.title == product.title);
    }
  }

  // Check if item is in wishlist
  bool isInWishlist(ProductCardModel product) {
    if (product.id != null) {
      return wishlistItems.any((item) => item.id == product.id);
    } else {
      return wishlistItems.any((item) => item.title == product.title);
    }
  }

  // Toggle wishlist status
  void toggleWishlist(ProductCardModel product) {
    if (isInWishlist(product)) {
      removeFromWishlist(product);
    } else {
      addToWishlist(product);
    }
  }
}
