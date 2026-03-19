import 'dart:async';

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
import '../services/location_service.dart';

import '../model/order_model.dart';
import 'address_controller.dart';
import 'orders_controller.dart';
import 'package:uuid/uuid.dart';

class CartController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  StreamSubscription? _stockSubscription;
  Worker? _cartWorker;

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

  double get couponDiscountValue {
    if (appliedCoupon.value == 'KISSAN20') {
      return subtotal * 0.20;
    } else if (appliedCoupon.value == 'FRESH50') {
      return (subtotal >= 50) ? 50.0 : subtotal;
    }
    return 0;
  }

  double get autoDiscountValue {
     if (appliedCoupon.value.isEmpty && subtotal >= 499) {
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

    // Check if item is in stock at all
    if (!product.inStock || product.stockCount <= 0) {
      Get.snackbar(
        'Out of Stock',
        'Sorry, ${product.title} is currently out of stock.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
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
          availableStock: product.stockCount,
          inStock: product.inStock,
        );


    final existingIndex = cartItems.indexWhere((i) => i.id == productId);

    if (existingIndex >= 0) {
      // Check stock limit
      if (cartItems[existingIndex].count + quantity > cartItems[existingIndex].availableStock) {
        Get.snackbar('Stock Limit Reached', 'Only ${cartItems[existingIndex].availableStock} units available for ${product.title}',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return false;
      }
      // Item already exists, increase count
      cartItems[existingIndex].count += quantity;
      cartItems.refresh();
    } else {
      // New item, add to cart
      // Need a way to get availableStock for new item without waiting for validation
      // For now, assume product has it or fetch it. 
      // Actually, I'll update CartItem to have a fallback or pass it from ProductCardModel if added.
      // Since ProductCardModel doesn't have it, I'll trigger a validation or assume a default and update.
      cartItems.add(cartItem);
      validateCartItems(); // Re-validate to get correct stock
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

    // Check if item is in stock
    if (!item.inStock || item.availableStock <= 0) {
      Get.snackbar(
        'Out of Stock',
        'Sorry, ${item.name} is currently out of stock.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final existingIndex = cartItems.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      if (cartItems[existingIndex].count + 1 > cartItems[existingIndex].availableStock) {
        Get.snackbar('Stock Limit Reached', 'Only ${cartItems[existingIndex].availableStock} units available.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return false;
      }
      cartItems[existingIndex].count++;
      cartItems.refresh();
    } else {
      cartItems.add(item);
      validateCartItems();
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
      if (cartItems[index].count + 1 > cartItems[index].availableStock) {
        Get.snackbar('Stock Limit Reached', 'Only ${cartItems[index].availableStock} units available.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
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
    _startStockListener();
    validateCartItems();
    _initializeRazorpay();
  }

  void _startStockListener() {
    // Listen to changes in cartItems to restart stock synchronization if IDs change
    _cartWorker = ever(cartItems, (List<CartItem> items) {
      _updateStockSubscription(items);
    });
    
    // Initial setup
    _updateStockSubscription(cartItems);
  }

  void _updateStockSubscription(List<CartItem> items) {
    _stockSubscription?.cancel();
    if (items.isEmpty) return;

    final productIds = items.map((item) => item.id).toList();
    
    // Firestore whereIn limit is 30. If cart > 30, we'd need chunks.
    // For this app, 30 is likely sufficient.
    final limitedIds = productIds.take(30).toList();

    _stockSubscription = _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: limitedIds)
        .snapshots()
        .listen((snapshot) {
      bool changed = false;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = doc.id;
        final index = cartItems.indexWhere((item) => item.id == productId);
        
        if (index >= 0) {
          final double freshPrice = (data['price'] ?? 0).toDouble();
          final int freshStock = (data['stockCount'] ?? 0).toInt();
          final bool freshInStock = (data['inStock'] ?? true) && freshStock > 0;

          if (cartItems[index].price != freshPrice || 
              cartItems[index].availableStock != freshStock || 
              cartItems[index].inStock != freshInStock) {
            
            cartItems[index].price = freshPrice;
            cartItems[index].availableStock = freshStock;
            cartItems[index].inStock = freshInStock;
            
            // Cap quantity if it exceeds stock
            if (cartItems[index].count > freshStock && freshStock >= 0) {
              cartItems[index].count = freshStock;
            }
            
            changed = true;
          }
        }
      }
      
      if (changed) {
        cartItems.refresh();
        _saveToHive();
      }
    });
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
    _stockSubscription?.cancel();
    _cartWorker?.dispose();
    super.onClose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (Get.isDialogOpen ?? false) Get.back();
    
    // Show loading while processing order
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: Color(0xFF0d9488)),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await placeOrder(paymentId: response.paymentId);
      
      if (success) {
        // Refresh orders list
        if (Get.isRegistered<OrdersController>()) {
          Get.find<OrdersController>().loadOrders();
        }
        
        // Navigate to My Orders with success popup flag
        Get.offAllNamed(AppRoutes.myOrdersRoute, arguments: {
          'showSuccessPopup': true,
          'paymentId': response.paymentId,
          'orderType': 'Online',
        });
      }
    } catch (e) {
      debugPrint("Error in _handlePaymentSuccess: $e");
      Get.snackbar(
        'Order Processing Failed',
        'Your payment (ID: ${response.paymentId}) was successful but we encountered an error. Please contact support.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
    } finally {
      // Ensure loading is ALWAYS dismissed if it's still there
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar(
      'External Wallet',
      'Wallet: ${response.walletName}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> processPayment() async {
    final user = _authController.firebaseUser.value;
    if (user == null) {
      Get.toNamed(AppRoutes.loginScreen);
      return;
    }

    // Step 1: Validate prices and stock first
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF0d9488))),
      barrierDismissible: false,
    );
    await validateCartItems();
    Get.back();

    // Check if any items became out of stock
    if (cartItems.any((item) => !item.inStock)) {
      Get.snackbar('Out of Stock', 'Some items in your cart are now out of stock. Please review.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final razorpayKey = dotenv.env['RAZORPAY_API_KEY'];
    if (razorpayKey == null || razorpayKey.isEmpty) {
      Get.snackbar('Config Error', 'Razorpay API Key not found in .env');
      return;
    }

    // Show loading dialog while Razorpay is opening
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0d9488),
        ),
      ),
      barrierDismissible: false,
    );

    var options = {
      'key': razorpayKey,
      'amount': (total * 100).toInt(), // Amount in paise
      'name': 'Kissan Fresh',
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? ''
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
      
      // Auto-close dialog after 2 seconds (Razorpay UI should be up by then)
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.isDialogOpen ?? false) Get.back();
      });
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Error: $e');
    }
  }

  Future<bool> placeOrder({String? paymentId, String paymentStatus = 'paid', String orderType = 'Online'}) async {
    final user = _authController.firebaseUser.value;
    if (user == null) throw Exception('User not logged in');

    final String orderId = const Uuid().v4();
    final String orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    
    // Resolve delivery address from multiple sources
    final String deliveryAddress = _resolveDeliveryAddress();

    final order = OrderModel(
      id: orderId,
      userId: user.uid,
      orderNumber: orderNumber,
      paymentId: paymentId, // Added paymentId to track post-payment
      items: cartItems.map((item) => OrderItem(
        productId: item.id,
        title: item.name,
        image: item.image,
        quantity: item.count,
        price: item.price,
      )).toList(),
      totalAmount: total,
      subtotal: subtotal,
      discount: autoDiscountValue,
      couponDiscount: couponDiscountValue,
      deliveryFee: deliveryFee,
      orderDate: DateTime.now(),
      status: OrderStatus.processing,
      deliveryAddress: deliveryAddress,
      paymentStatus: paymentStatus,
      orderType: orderType,
    );
    // 4. Use transaction to ensure perfect stock safety
    try {
      await _firestore.runTransaction((transaction) async {
        // First, READ all product documents to check stock
        for (var item in cartItems) {
          final productRef = _firestore.collection('products').doc(item.id);
          final snap = await transaction.get(productRef);
          if (!snap.exists) {
            throw "Product ${item.name} no longer available.";
          }
          
          final data = snap.data() as Map<String, dynamic>;
          final int currentStock = (data['stockCount'] ?? 0).toInt();
          
          if (currentStock < item.count) {
            throw "Insufficient stock for ${item.name}. Available: $currentStock";
          }
        }

        // Second, UPDATE stock and CREATE order
        final orderDoc = _firestore.collection('orders').doc(orderId);
        transaction.set(orderDoc, order.toJson());

        for (var item in cartItems) {
          final productRef = _firestore.collection('products').doc(item.id);
          transaction.update(productRef, {
            'stockCount': FieldValue.increment(-item.count),
          });
        }
      });

      // Transaction successful
      clearCart();
      return true;
    } catch (e) {
      debugPrint("Transaction failed: $e");
      
      // If payment was already done (paymentId != null), we must record this failure
      if (paymentId != null) {
        await _recordFailedOrder(order, e.toString());
      }

      Get.snackbar(
        "Order Issue - Refund Initiated",
        e.toString().contains("Insufficient stock") 
            ? "${e.toString()}. Since your payment was successful, a full refund has been automatically initiated." 
            : "An issue occurred while finalizing your order. A full refund has been initiated. Payment ID: $paymentId",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 12),
      );
      
      // Trigger a refresh of stock in cart
      validateCartItems();
      return false;
    }
  }

  /// Resolves the delivery address by checking multiple sources:
  /// 1. AddressController (user-selected address)
  /// 2. LocationService (GPS-detected address)
  /// 3. Hive persisted address
  String _resolveDeliveryAddress() {
    const invalidValues = [
      'Select delivery address',
      'Default Address',
      '',
      'Fetching address...',
      'Address not found',
      'Unable to fetch address',
      'No address selected',
    ];

    // 1. Try AddressController (user explicitly selected an address)
    try {
      if (Get.isRegistered<AddressController>()) {
        final addr = Get.find<AddressController>().currentAddress.value;
        if (!invalidValues.contains(addr)) return addr;
      }
    } catch (_) {}

    // 2. Try LocationService (GPS-detected address)
    try {
      if (Get.isRegistered<LocationService>()) {
        final addr = Get.find<LocationService>().currentAddress.value;
        if (addr != null && !invalidValues.contains(addr)) return addr;
      }
    } catch (_) {}

    // 3. Try Hive persisted address
    try {
      final box = Hive.box('user_settings');
      final addr = box.get('current_address');
      if (addr != null && addr is String && !invalidValues.contains(addr)) {
        return addr;
      }
      // Also check last known address from LocationService
      final lastAddr = box.get('last_known_address');
      if (lastAddr != null && lastAddr is String && !invalidValues.contains(lastAddr)) {
        return lastAddr;
      }
    } catch (_) {}

    return 'Address not available';
  }

  Future<void> _recordFailedOrder(OrderModel order, String error) async {
    try {
      await _firestore.collection('failed_orders').add({
        'orderData': order.toJson(),
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'paid_but_stock_failed',
        'refundStatus': 'pending',
        'totalAmount': order.totalAmount,
        'currency': 'INR',
        'paymentId': order.paymentId,
      });
    } catch (e) {
      debugPrint("Critical: Failed to record failed order: $e");
    }
  }

  /// Place a Cash on Delivery order without Razorpay.
  Future<void> placeCodOrder() async {
    final user = _authController.firebaseUser.value;
    if (user == null) {
      Get.toNamed(AppRoutes.loginScreen);
      return;
    }

    // Validate stock first
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF0d9488))),
      barrierDismissible: false,
    );
    await validateCartItems();
    Get.back();

    if (cartItems.any((item) => !item.inStock)) {
      Get.snackbar('Out of Stock', 'Some items in your cart are now out of stock. Please review.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF0d9488))),
      barrierDismissible: false,
    );

    try {
      final success = await placeOrder(
        paymentStatus: 'pending',
        orderType: 'COD',
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (success) {
        if (Get.isRegistered<OrdersController>()) {
          Get.find<OrdersController>().loadOrders();
        }

        // Navigate to My Orders with success popup flag
        Get.offAllNamed(AppRoutes.myOrdersRoute, arguments: {
          'showSuccessPopup': true,
          'orderType': 'COD',
        });
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Error in placeCodOrder: $e');
      Get.snackbar(
        'Order Failed',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
               final bool freshStockStatus = data['inStock'] ?? true;
               final int freshStockCount = (data['stockCount'] ?? 0).toInt(); // Default to 0 if not specified
               
               if (cartItems[i].price != freshPrice || 
                   cartItems[i].inStock != freshStockStatus || 
                   cartItems[i].availableStock != freshStockCount) {
                 cartItems[i].price = freshPrice;
                 cartItems[i].inStock = freshStockStatus;
                 cartItems[i].availableStock = freshStockCount;
                 
                 // If current count exceeds new stock, cap it
                 if (cartItems[i].count > freshStockCount) {
                   cartItems[i].count = freshStockCount;
                 }
                 // If product is now out of stock, set inStock to false
                 if (freshStockCount <= 0) {
                   cartItems[i].inStock = false;
                 } else {
                   cartItems[i].inStock = true;
                 }
                 
                 needsUpdate = true;
               }
            }
          } else {
             // Product deleted from db, forcefully flag out of stock
             if (cartItems[i].inStock != false || cartItems[i].availableStock != 0 || cartItems[i].count != 0) {
                 cartItems[i].inStock = false;
                 cartItems[i].availableStock = 0;
                 cartItems[i].count = 0; // Set count to 0 if product is gone
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
  int availableStock;
  bool inStock;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.count = 1,
    this.availableStock = 0,
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
      'availableStock': availableStock,
      'inStock': inStock,
    };
  }

  // Create CartItem from Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'],
      count: json['count'] ?? 1,
      availableStock: json['availableStock'] ?? 0,
      inStock: json['inStock'] ?? true,
    );
  }
}