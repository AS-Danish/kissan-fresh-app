import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/product_card_model.dart';
import '../routes/app_routes.dart';
import 'auth_controller.dart';
import '../services/location_service.dart';

import '../model/order_model.dart';
import 'address_controller.dart';
import 'homepage_controller.dart';
import 'orders_controller.dart';
import 'slot_selection_controller.dart';
import 'user_activity_controller.dart';
import '../model/coupon_model.dart';

class CartController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  StreamSubscription? _stockSubscription;
  Worker? _cartWorker;

  // Observable list of cart items
  RxList<CartItem> cartItems = <CartItem>[].obs;

  // Track current route to show/hide global cart snackbar
  RxString currentRoute = ''.obs;

  final Box _cartBox = Hive.box('cart_box');

  // Processing state to prevent double taps
  RxBool isProcessingOrder = false.obs;

  // Coupon State
  RxString appliedCoupon = ''.obs;
  Rxn<CouponModel> activeCouponModel = Rxn<CouponModel>();
  RxBool isApplyingCoupon = false.obs;

  // Computed values
  double get subtotal {
    return cartItems.fold(
      0,
      (accSum, item) => accSum + (item.price * item.count),
    );
  }

  double get deliveryFee {
    // Free delivery above ₹299
    return subtotal >= 299 ? 0 : 20;
  }

  double get discount {
    if (activeCouponModel.value != null) {
      double applicableSubtotal = _calculateApplicableSubtotal(activeCouponModel.value!);
      if (applicableSubtotal == 0) return 0;
      
      double calculatedDiscount = 0;
      if (activeCouponModel.value!.discountType == 'percentage') {
        calculatedDiscount = applicableSubtotal * (activeCouponModel.value!.discountValue / 100);
      } else {
        // flat/fixed
        calculatedDiscount = activeCouponModel.value!.discountValue;
      }
      return calculatedDiscount > applicableSubtotal ? applicableSubtotal : calculatedDiscount;
    }

    // Legacy auto-applied discount (15% off above ₹499)
    if (subtotal >= 499) {
      return subtotal * 0.15;
    }
    return 0;
  }

  double get couponDiscountValue {
    if (activeCouponModel.value != null) {
      double applicableSubtotal = _calculateApplicableSubtotal(activeCouponModel.value!);
      if (applicableSubtotal == 0) return 0;
      
      double calculatedDiscount = 0;
      if (activeCouponModel.value!.discountType == 'percentage') {
        calculatedDiscount = applicableSubtotal * (activeCouponModel.value!.discountValue / 100);
      } else {
        calculatedDiscount = activeCouponModel.value!.discountValue;
      }
      return calculatedDiscount > applicableSubtotal ? applicableSubtotal : calculatedDiscount;
    }
    return 0;
  }

  double get autoDiscountValue {
    if (activeCouponModel.value == null && subtotal >= 499) {
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

  String get currentOrigin {
    return Get.find<HomepageController>().currentOrigin;
  }

  // Coupon Methods
  Future<void> applyCoupon(String code) async {
    if (code.isEmpty) return;
    final normalizedCode = code.trim().toUpperCase();

    try {
      isApplyingCoupon.value = true;
      final querySnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: normalizedCode)
          .where('isActive', isEqualTo: true)
          .where('productType', isEqualTo: currentOrigin)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar('Invalid Coupon', 'The coupon code you entered is not valid.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final coupon = CouponModel.fromJson(querySnapshot.docs.first.data());
      await applyCouponModel(coupon);
    } catch (e) {
      debugPrint("Error applying coupon: $e");
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  Future<void> applyCouponModel(CouponModel coupon) async {
    final validationError = getCouponValidation(coupon);
    if (validationError != null) {
      Get.snackbar('Cannot Apply', validationError,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Secondary check for per-user limit (requires DB fetch)
    if (coupon.maxUsesPerUser != null) {
      final userOrders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _authController.firebaseUser.value!.uid)
          .where('couponCode', isEqualTo: coupon.code)
          .count()
          .get();
      if (userOrders.count != null && userOrders.count! >= coupon.maxUsesPerUser!) {
        Get.snackbar('Limit Exceeded', 'You have already used this coupon maximum times.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    activeCouponModel.value = coupon;
    appliedCoupon.value = coupon.code;
    cartItems.refresh();
    
    Get.snackbar('Coupon Applied', 'Discount applied successfully!',
        backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.TOP);
  }

  String? getCouponValidation(CouponModel coupon) {
    if (_authController.firebaseUser.value == null) {
      return 'Login Required';
    }

    if (!coupon.isActive) {
      return 'Coupon is no longer active';
    }

    if (coupon.productType != currentOrigin) {
      return 'Not applicable for $currentOrigin';
    }

    if (coupon.minOrderValue != null && subtotal < coupon.minOrderValue!) {
      return 'Min order ₹${coupon.minOrderValue?.toStringAsFixed(0)} required';
    }

    if (coupon.totalUsageLimit != null && coupon.currentUsageCount >= coupon.totalUsageLimit!) {
      return 'Coupon usage limit reached';
    }

    // Check if there are applicable products in the cart
    double applicableSubtotal = _calculateApplicableSubtotal(coupon);
    if (applicableSubtotal == 0) {
      return 'No applicable products in cart';
    }

    return null; // Valid
  }

  double _calculateApplicableSubtotal(CouponModel coupon) {
    // If applyTo is "all" or specific restrictions are null, apply to all items
    if (coupon.applyTo == 'all' || (coupon.applicableCategory == null && coupon.applicableProduct == null)) {
      return subtotal;
    }
    
    double appSubtotal = 0;
    for (var item in cartItems) {
      bool isApplicable = false;
      
      if (coupon.applicableCategory != null && item.category == coupon.applicableCategory) {
        isApplicable = true;
      } else if (coupon.applicableProduct != null && item.id == coupon.applicableProduct) {
        isApplicable = true;
      }
      
      if (isApplicable) {
        appSubtotal += (item.price * item.count);
      }
    }
    return appSubtotal;
  }

  void removeCoupon() {
    appliedCoupon.value = '';
    activeCouponModel.value = null;
    cartItems.refresh();
    Get.snackbar(
      'Coupon Removed',
      'Coupon has been removed from your cart.',
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  // Add product to cart from ProductCardModel
  bool addToCart(ProductCardModel product, int quantity) {
    // Track activity
    try {
      if (Get.isRegistered<UserActivityController>()) {
        Get.find<UserActivityController>().trackAddToCart(product);
      }
    } catch (e) {
      debugPrint("Error tracking cart activity: $e");
    }

    if (_authController.firebaseUser.value == null) {
      Get.toNamed(AppRoutes.loginScreen);
      Get.snackbar(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF14B8A6),
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
      mrp: product.mrp,
      image: product.image,
      count: quantity,
      availableStock: product.stockCount,
      inStock: product.inStock,
      category: product.category,
    );

    final existingIndex = cartItems.indexWhere((i) => i.id == productId);

    if (existingIndex >= 0) {
      // Check stock limit
      if (cartItems[existingIndex].count + quantity >
          cartItems[existingIndex].availableStock) {
        Get.snackbar(
          'Stock Limit Reached',
          'Only ${cartItems[existingIndex].availableStock} units available for ${product.title}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
      // Item already exists, increase count
      cartItems[existingIndex].count += quantity;
      cartItems.refresh();
    } else {
      // New item, add to cart
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
        backgroundColor: const Color(0xFF14B8A6),
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
      if (cartItems[existingIndex].count + 1 >
          cartItems[existingIndex].availableStock) {
        Get.snackbar(
          'Stock Limit Reached',
          'Only ${cartItems[existingIndex].availableStock} units available.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
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
        Get.snackbar(
          'Stock Limit Reached',
          'Only ${cartItems[index].availableStock} units available.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
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
              final bool freshInStock =
                  (data['inStock'] ?? true) && freshStock > 0;

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
      const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      barrierDismissible: false,
    );

    try {
      final orderId = await placeOrder(paymentId: response.paymentId);

      if (orderId != null) {
        // Refresh orders list
        if (Get.isRegistered<OrdersController>()) {
          Get.find<OrdersController>().loadOrders();
        }

        // Navigate to My Orders with success popup flag
        Get.offAllNamed(
          AppRoutes.myOrdersRoute,
          arguments: {
            'showSuccessPopup': true,
            'paymentId': response.paymentId,
            'orderId': orderId,
            'orderType': 'Online',
          },
        );
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
      isProcessingOrder.value = false;
      // Ensure loading is ALWAYS dismissed if it's still there
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessingOrder.value = false;
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
    isProcessingOrder.value = false;
    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar(
      'External Wallet',
      'Wallet: ${response.walletName}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> processPayment() async {
    if (isProcessingOrder.value) return;
    isProcessingOrder.value = true;

    final user = _authController.firebaseUser.value;
    if (user == null) {
      isProcessingOrder.value = false;
      Get.toNamed(AppRoutes.loginScreen);
      return;
    }

    // Step 0: Validate Service Area
    final resolved = _resolveDeliveryAddressData();
    if (!_validateServiceArea(resolved)) {
      isProcessingOrder.value = false;
      return;
    }

    // Step 1: Validate prices and stock first
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      barrierDismissible: false,
    );
    await validateCartItems();
    Get.back();

    // Check if any items became out of stock
    if (cartItems.any((item) => !item.inStock)) {
      Get.snackbar(
        'Out of Stock',
        'Some items in your cart are now out of stock. Please review.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isProcessingOrder.value = false;
      return;
    }

    final razorpayKey = dotenv.env['RAZORPAY_API_KEY'];
    if (razorpayKey == null || razorpayKey.isEmpty) {
      Get.snackbar('Config Error', 'Razorpay API Key not found in .env');
      isProcessingOrder.value = false;
      return;
    }

    // Show loading dialog while Razorpay is opening
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      barrierDismissible: false,
    );

    var options = {
      'key': razorpayKey,
      'amount': (total * 100).toInt(), // Amount in paise
      'name': 'Kissan Fresh',
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': user.phoneNumber ?? '', 'email': user.email ?? ''},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);

      // Auto-close loading dialog after a short delay
      // The Razorpay UI should replace it
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (Get.isDialogOpen ?? false) Get.back();
      });
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Exception opening Razorpay: $e');
      Get.snackbar(
        'Payment Initialization Failed',
        'Could not open payment gateway. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> placeOrder({
    String? paymentId,
    String paymentStatus = 'paid',
    String orderType = 'Online',
  }) async {
    final user = _authController.firebaseUser.value;
    if (user == null) throw Exception('User not logged in');

    final String orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Resolve delivery address from multiple sources
    final resolved = _resolveDeliveryAddressData();

    final order = OrderModel(
      id: '',
      userId: user.uid,
      orderNumber: orderNumber,
      paymentId: paymentId, // Added paymentId to track post-payment
      items: cartItems
          .map(
            (item) => OrderItem(
              productId: item.id,
              title: item.name,
              unit: item.quantity,
              image: item.image,
              quantity: item.count,
              price: item.price,
              mrp: item.mrp,
            ),
          )
          .toList(),
      totalAmount: total,
      subtotal: subtotal,
      discount: autoDiscountValue,
      couponDiscount: couponDiscountValue,
      deliveryFee: deliveryFee,
      orderDate: DateTime.now(),
      status: OrderStatus.processing,
      deliveryAddress: resolved.address,
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      paymentStatus: paymentStatus,
      orderType: orderType,
      slotId: Get.find<SlotSelectionController>().selectedSlotId.value,
      couponCode: appliedCoupon.value.isEmpty ? null : appliedCoupon.value,
    );
    // 4. Call Cloud Function to process order creation and assignment transactionally
    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'createOrder',
      );

      // We pass the order data. The CF expects {'order': orderMap}
      final HttpsCallableResult result = await httpsCallable.call({'order': order.toJson()});

      // The CF returns { success: true, orderId: "KF-XXXXXX", ... }
      if (result.data != null && result.data['success'] == true) {
        final String? serverOrderId = result.data['orderId'];
        
        // Increment coupon usage if applied
        if (activeCouponModel.value != null && appliedCoupon.value.isNotEmpty) {
          try {
            final querySnapshot = await _firestore
                .collection('coupons')
                .where('code', isEqualTo: appliedCoupon.value)
                .limit(1)
                .get();
            if (querySnapshot.docs.isNotEmpty) {
              final docRef = querySnapshot.docs.first.reference;
              await docRef.update({
                'currentUsageCount': FieldValue.increment(1)
              });
            }
          } catch (e) {
            debugPrint("Failed to update coupon usage: $e");
          }
        }
        
        clearCart();
        return serverOrderId ?? ''; // Return the actual ID from server
      }
      return null;
    } catch (e) {
      debugPrint("Order processing failed: $e");

      // If payment was already done (paymentId != null), we must record this failure
      if (paymentId != null) {
        await _recordFailedOrder(order, e.toString());
      }

      // Close the loading dialog BEFORE pushing a snackbar.
      // Otherwise, the caller's Get.back() will mistakenly pop the snackbar instead of the dialog.
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      String title = paymentId != null
          ? "Order Issue - Refund Initiated"
          : "Order Failed";
      String message = "";
      if (e.toString().contains("Insufficient stock")) {
        message = "Insufficient stock for some items.";
        if (paymentId != null) {
          message += " A full refund has been automatically initiated.";
        }
      } else if (e.toString().contains("no_slots_available") ||
          e.toString().contains("failed-precondition") ||
          e.toString().contains("active slots")) {
        message =
            "No delivery slots are currently available. Please try again later.";
        if (paymentId != null) {
          message += " Your payment will be fully refunded automatically.";
        }
      } else {
        message = "An issue occurred while finalizing your order.";
        if (paymentId != null) {
          message +=
              " A full refund has been initiated. Payment ID: $paymentId";
        }
      }

      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );

      // Trigger a refresh of stock in cart
      validateCartItems();
      return null;
    }
  }

  /// Resolves the delivery address by checking multiple sources:
  /// 1. AddressController (user-selected address)
  /// 2. LocationService (GPS-detected address)
  /// 3. Hive persisted address
  String _resolveDeliveryAddress() {
    return _resolveDeliveryAddressData().address;
  }

  /// Helper to check if the resolved address is within the service area (30km)
  bool _validateServiceArea(ResolvedAddress resolved) {
    final locationService = Get.find<LocationService>();

    // If we have coordinates, use the precise distance check
    if (resolved.latitude != null && resolved.longitude != null) {
      final isServiceable = locationService.isWithinServiceArea(
        resolved.latitude,
        resolved.longitude,
      );

      if (!isServiceable) {
        Get.snackbar(
          'Service Unavailable',
          'We are not in your area yet. Currently, we only serve Chattrapati Sambhaji Nagar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          icon: const Icon(Icons.location_off_rounded, color: Colors.white),
        );
        return false;
      }
      return true;
    }

    // Fallback if no coordinates: If it's a valid string, return true but log it.
    // However, it's safer to require map selection for precision.
    if (resolved.address == 'Address not available') {
      Get.snackbar(
        'Address Error',
        'Please select a valid delivery address.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  /// Resolves the delivery address and coordinates from multiple sources
  ResolvedAddress _resolveDeliveryAddressData() {
    const invalidValues = [
      'Select delivery address',
      'Default Address',
      '',
      'Fetching address...',
      'Address not found',
      'Unable to fetch address',
      'No address selected',
    ];

    // Priority 1: AddressController (user explicitly selected an address)
    try {
      if (Get.isRegistered<AddressController>()) {
        final ctrl = Get.find<AddressController>();
        final addr = ctrl.currentAddress.value;
        if (!invalidValues.contains(addr)) {
          return ResolvedAddress(
            address: addr,
            latitude: ctrl.selectedLocation.value.latitude,
            longitude: ctrl.selectedLocation.value.longitude,
          );
        }
      }
    } catch (_) {}

    // Priority 2: LocationService (GPS-detected address)
    try {
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        final addr = loc.currentAddress.value;
        if (addr != null && !invalidValues.contains(addr)) {
          return ResolvedAddress(
            address: addr,
            latitude: loc.currentLocation.value?.latitude,
            longitude: loc.currentLocation.value?.longitude,
          );
        }
      }
    } catch (_) {}

    // Priority 3: Hive persisted settings
    try {
      final box = Hive.box('user_settings');
      final addr = box.get('current_address');
      final lat = box.get('last_known_lat');
      final lng = box.get('last_known_lng');

      if (addr != null && addr is String && !invalidValues.contains(addr)) {
        return ResolvedAddress(
          address: addr,
          latitude: lat,
          longitude: lng,
        );
      }
    } catch (_) {}

    return ResolvedAddress(address: 'Address not available');
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
    if (isProcessingOrder.value) return;
    isProcessingOrder.value = true;

    final user = _authController.firebaseUser.value;
    if (user == null) {
      isProcessingOrder.value = false;
      Get.toNamed(AppRoutes.loginScreen);
      return;
    }

    // Step 0: Validate Service Area
    final resolved = _resolveDeliveryAddressData();
    if (!_validateServiceArea(resolved)) {
      isProcessingOrder.value = false;
      return;
    }

    // Validate stock first
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      barrierDismissible: false,
    );
    await validateCartItems();
    Get.back();

    if (cartItems.any((item) => !item.inStock)) {
      Get.snackbar(
        'Out of Stock',
        'Some items in your cart are now out of stock. Please review.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isProcessingOrder.value = false;
      return;
    }

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      barrierDismissible: false,
    );

    try {
      final serverOrderId = await placeOrder(
        paymentStatus: 'pending',
        orderType: 'COD',
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (serverOrderId != null) {
        if (Get.isRegistered<OrdersController>()) {
          Get.find<OrdersController>().loadOrders();
        }

        // Navigate to My Orders with success popup flag
        Get.offAllNamed(
          AppRoutes.myOrdersRoute,
          arguments: {
            'showSuccessPopup': true,
            'orderId': serverOrderId,
            'orderType': 'COD',
          },
        );
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
    } finally {
      isProcessingOrder.value = false;
    }
  }

  Future<void> validateCartItems() async {
    if (cartItems.isEmpty) return;

    bool needsUpdate = false;
    try {
      final List<String> itemIds = cartItems.map((e) => e.id).toList();

      // Process in chunks of 30 due to whereIn limits
      for (int i = 0; i < itemIds.length; i += 30) {
        final chunk = itemIds.skip(i).take(30).toList();

        final querySnap = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final docMap = {for (var doc in querySnap.docs) doc.id: doc};

        for (int j = 0; j < cartItems.length; j++) {
          var cartItem = cartItems[j];
          if (!chunk.contains(cartItem.id)) continue;

          if (docMap.containsKey(cartItem.id)) {
            final data = docMap[cartItem.id]!.data();
            final double freshPrice = (data['price'] ?? 0).toDouble();
            final int freshStockCount = (data['stockCount'] ?? 0).toInt();
            final bool freshStockStatus =
                (data['inStock'] ?? true) && freshStockCount > 0;

            if (cartItem.price != freshPrice ||
                cartItem.inStock != freshStockStatus ||
                cartItem.availableStock != freshStockCount) {
              cartItem.price = freshPrice;
              cartItem.inStock = freshStockStatus;
              cartItem.availableStock = freshStockCount;

              if (cartItem.count > freshStockCount) {
                cartItem.count = freshStockCount;
              }
              if (freshStockCount <= 0) {
                cartItem.inStock = false;
              } else {
                cartItem.inStock = true;
              }
              needsUpdate = true;
            }
          } else {
            // Product deleted from db
            if (cartItem.inStock != false ||
                cartItem.availableStock != 0 ||
                cartItem.count != 0) {
              cartItem.inStock = false;
              cartItem.availableStock = 0;
              cartItem.count = 0;
              needsUpdate = true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error validating cart items: $e");
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
        cartItems.value = itemsList
            .map((item) => CartItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      Get.snackbar('Cart Error', 'Failed to load local cart items.');
    }
  }

  void _saveToHive() {
    try {
      List<Map<String, dynamic>> jsonData = cartItems
          .map((item) => item.toJson())
          .toList();
      _cartBox.put('cart_items_list', jsonEncode(jsonData));
    } catch (e) {
      debugPrint("Error saving cart to Hive: $e");
    }
  }
}

class ResolvedAddress {
  final String address;
  final double? latitude;
  final double? longitude;

  ResolvedAddress({
    required this.address,
    this.latitude,
    this.longitude,
  });
}

class CartItem {
  final String id;
  final String name;
  final String quantity;
  double price;
  double? mrp;
  final String image;
  int count;
  int availableStock;
  bool inStock;
  String? category;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.mrp,
    required this.image,
    this.count = 1,
    this.availableStock = 0,
    this.inStock = true,
    this.category,
  });

  // Convert CartItem to Map for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'mrp': mrp,
      'image': image,
      'count': count,
      'availableStock': availableStock,
      'inStock': inStock,
      'category': category,
    };
  }

  // Create CartItem from Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0).toDouble(),
      mrp: json['mrp'] != null ? (json['mrp']).toDouble() : null,
      image: json['image'],
      count: json['count'] ?? 1,
      availableStock: json['availableStock'] ?? 0,
      inStock: json['inStock'] ?? true,
      category: json['category'],
    );
  }
}
