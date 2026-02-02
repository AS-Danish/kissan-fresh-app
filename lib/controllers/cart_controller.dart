import 'package:get/get.dart';
import '../model/product_card_model.dart';

class CartController extends GetxController {
  // Observable list of cart items
  RxList<CartItem> cartItems = <CartItem>[].obs;

  // Computed values
  double get subtotal {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.count));
  }

  double get deliveryFee {
    // Free delivery above ₹299
    return subtotal >= 299 ? 0 : 20;
  }

  double get discount {
    // Example: 15% discount on orders above ₹499
    if (subtotal >= 499) {
      return subtotal * 0.15;
    }
    return 0;
  }

  double get total {
    return subtotal + deliveryFee - discount;
  }

  int get totalItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.count);
  }

  // Add product to cart from ProductCardModel
  void addToCart(ProductCardModel product, int quantity) {
    // Use product ID if available, otherwise use title
    final productId = product.id ?? product.title;

    final cartItem = CartItem(
      id: productId,
      name: product.title,
      quantity: product.unit,
      price: product.price,
      image: product.image,
      count: quantity,
    );

    final existingIndex = cartItems.indexWhere((i) => i.id == productId);

    if (existingIndex >= 0) {
      // Item already exists, increase count
      cartItems[existingIndex].count += quantity;
      cartItems.refresh();
    } else {
      // New item, add to cart
      cartItems.add(cartItem);
    }
  }

  // Methods
  void addItem(CartItem item) {
    final existingIndex = cartItems.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      cartItems[existingIndex].count++;
      cartItems.refresh();
    } else {
      cartItems.add(item);
    }
  }

  void removeItem(String itemId) {
    cartItems.removeWhere((item) => item.id == itemId);
  }

  void incrementItem(String itemId) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      cartItems[index].count++;
      cartItems.refresh();
    }
  }

  void decrementItem(String itemId) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (cartItems[index].count > 1) {
        cartItems[index].count--;
        cartItems.refresh();
      }
      // If count is 1, do nothing (don't remove the item)
    }
  }

  void clearCart() {
    cartItems.clear();
  }

  // Check if a product is in cart
  bool isInCart(String productId) {
    return cartItems.any((item) => item.id == productId);
  }

  // Get quantity of a specific product in cart
  int getProductQuantity(String productId) {
    final index = cartItems.indexWhere((item) => item.id == productId);
    return index >= 0 ? cartItems[index].count : 0;
  }

  @override
  void onInit() {
    super.onInit();
    // Load sample data
    _loadSampleData();
  }

  void _loadSampleData() {
    cartItems.addAll([
      CartItem(
        id: '1',
        name: 'Fresh Organic Tomatoes',
        quantity: '1 kg',
        price: 90.0,
        image: 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400',
        count: 2,
      ),
      CartItem(
        id: '2',
        name: 'Farm Fresh Spinach',
        quantity: '500 g',
        price: 90.0,
        image: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
        count: 3,
      ),
      CartItem(
        id: '3',
        name: 'Organic Carrots',
        quantity: '1 kg',
        price: 100.0,
        image: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400',
        count: 2,
      ),
    ]);
  }
}

class CartItem {
  final String id;
  final String name;
  final String quantity;
  final double price;
  final String image;
  int count;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.count = 1,
  });

  // Convert CartItem to Map for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image': image,
      'count': count,
    };
  }

  // Create CartItem from Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      image: json['image'],
      count: json['count'],
    );
  }
}