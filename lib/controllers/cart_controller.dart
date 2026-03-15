import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/product_card_model.dart';
import '../routes/AppRoutes.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;

  // Observable list of cart items
  RxList<CartItem> cartItems = <CartItem>[].obs;
  
  final Box _cartBox = Hive.box('cart_box');

  // Coupon State
  RxString appliedCoupon = ''.obs;

  // Computed values
  double get subtotal {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.count));
  }

  double get deliveryFee {
    // Free delivery above ₹299
    return subtotal >= 299 ? 0 : 20;
  }

  double get discount {
    // Priority: Applied Coupon (calculated dynamically)
    if (appliedCoupon.value == 'KISSAN20') {
      return subtotal * 0.20;
    } else if (appliedCoupon.value == 'FRESH50') {
      return (subtotal >= 50) ? 50.0 : subtotal;
    }
    
    // Legacy auto-applied discount (15% off above ₹499)
    if (subtotal >= 499) {
      return subtotal * 0.15;
    }
    return 0;
  }

  double get total {
    return subtotal + deliveryFee - discount;
  }

  int get totalItemCount {
    return cartItems.length;
  }

  // Coupon Methods
  void applyCoupon(String code) {
    if (code.isEmpty) return;
    
    final normalizedCode = code.trim().toUpperCase();
    
    if (normalizedCode == 'KISSAN20') {
      appliedCoupon.value = normalizedCode;
      Get.snackbar('Coupon Applied', '20% discount applied successfully!', 
        backgroundColor: Colors.green, colorText: Colors.white);
    } else if (normalizedCode == 'FRESH50') {
      appliedCoupon.value = normalizedCode;
      Get.snackbar('Coupon Applied', '₹50 discount applied successfully!',
        backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Invalid Coupon', 'The coupon code you entered is not valid.',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
    cartItems.refresh(); // Trigger total re-calc
  }

  void removeCoupon() {
    appliedCoupon.value = '';
    cartItems.refresh();
    Get.snackbar('Coupon Removed', 'Coupon has been removed from your cart.',
      backgroundColor: Colors.black87, colorText: Colors.white);
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
      inStock: product.inStock,
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
    validateCartItems();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.snackbar(
      'Payment Successful',
      'Transaction ID: ${response.paymentId}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
    clearCart();
    Get.offAllNamed(AppRoutes.homepageRoute); // Go back to home after success
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Wallet: ${response.walletName}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void processPayment() {
    final razorpayKey = dotenv.env['RAZORPAY_API_KEY'];
    if (razorpayKey == null || razorpayKey.isEmpty) {
      Get.snackbar('Config Error', 'Razorpay API Key not found in .env');
      return;
    }

    var options = {
      'key': razorpayKey,
      'amount': (total * 100).toInt(), // Amount in paise
      'name': 'Kissan Fresh',
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': _authController.firebaseUser.value?.phoneNumber ?? '',
        'email': _authController.firebaseUser.value?.email ?? ''
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  // Ensures exact stock status and price maps directly from Firestore.
  Future<void> validateCartItems() async {
    if (cartItems.isEmpty) return;

    bool needsUpdate = false;
    for (int i = 0; i < cartItems.length; i++) {
        try {
          final docSnap = await _firestore.collection('products').doc(cartItems[i].id).get();
          if (docSnap.exists) {
            final data = docSnap.data();
            if (data != null) {
               final double freshPrice = (data['price'] ?? 0).toDouble();
               final bool freshStock = data['inStock'] ?? true;
               
               if (cartItems[i].price != freshPrice || cartItems[i].inStock != freshStock) {
                 cartItems[i].price = freshPrice;
                 cartItems[i].inStock = freshStock;
                 needsUpdate = true;
               }
            }
          } else {
             // Product deleted from db, forcefully flag out of stock
             if (cartItems[i].inStock != false) {
                 cartItems[i].inStock = false;
                 needsUpdate = true;
             }
          }
        } catch (e) {
          print("Error validating cart item ${cartItems[i].id}: $e");
        }
    }

    if (needsUpdate) {
      cartItems.refresh();
      _saveToHive();
    }
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
  double price;
  final String image;
  int count;
  bool inStock;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.count = 1,
    this.inStock = true,
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
      'inStock': inStock,
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
      inStock: json['inStock'] ?? true,
    );
  }
}