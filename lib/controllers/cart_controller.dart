import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  // Observable list of cart items
  RxList<CartItem> cartItems = <CartItem>[].obs;
  
  final Box _cartBox = Hive.box('cart_box');

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
  bool addToCart(ProductCardModel product, int quantity) {
    if (_authController.firebaseUser.value == null) {
      Get.toNamed(AppRoutes.loginScreen);
      Get.snackbar(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0d9488),
        colorText: Colors.white,
      );
      return false;
    }

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
    _saveToHive();
    return true;
  }

  // Methods
  bool addItem(CartItem item) {
    if (_authController.firebaseUser.value == null) {
      Get.toNamed(AppRoutes.loginScreen);
      Get.snackbar(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0d9488),
        colorText: Colors.white,
      );
      return false;
    }

    final existingIndex = cartItems.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      cartItems[existingIndex].count++;
      cartItems.refresh();
    } else {
      cartItems.add(item);
    }
    _saveToHive();
    return true;
  }

  void removeItem(String itemId) {
    cartItems.removeWhere((item) => item.id == itemId);
    _saveToHive();
  }

  void incrementItem(String itemId) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      cartItems[index].count++;
      cartItems.refresh();
      _saveToHive();
    }
  }

  void decrementItem(String itemId) {
    final index = cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (cartItems[index].count > 1) {
        cartItems[index].count--;
        cartItems.refresh();
        _saveToHive();
      }
      // If count is 1, do nothing (don't remove the item)
    }
  }

  void clearCart() {
    cartItems.clear();
    _saveToHive();
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
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final savedData = _cartBox.get('cart_items_list');
      if (savedData != null) {
        List<dynamic> itemsList = jsonDecode(savedData);
        cartItems.value = itemsList.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      Get.snackbar('Cart Error', 'Failed to load local cart items.');
    }
  }

  void _saveToHive() {
    try {
       List<Map<String, dynamic>> jsonData = cartItems.map((item) => item.toJson()).toList();
       _cartBox.put('cart_items_list', jsonEncode(jsonData));
    } catch (e) {
      print("Error saving cart to Hive: $e");
    }
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