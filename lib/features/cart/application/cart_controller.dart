import 'package:kissanfresh/core/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';
import 'package:kissanfresh/features/orders/application/orders_controller.dart';
import 'package:kissanfresh/features/delivery/application/slot_selection_controller.dart';
import 'package:kissanfresh/features/catalog/application/user_activity_controller.dart';
import 'package:kissanfresh/features/delivery/data/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'dart:async';

import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kissanfresh/features/checkout/data/checkout_repository.dart';
import 'package:kissanfresh/features/catalog/domain/product_card_model.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/features/auth/application/auth_controller.dart';

import 'package:kissanfresh/features/orders/domain/order_model.dart';
import 'package:kissanfresh/features/cart/domain/coupon_model.dart';

class CartController extends FeatureController with WidgetsBindingObserver {
  final Ref ref;

  CartController(this.ref);

  final _checkout = CheckoutRepository(
    FirebaseFunctions.instance,
    Hive.box('user_settings'),
  );
  Future<String?>? _statusCheck;
  Timer? _checkoutWatchdog;
  Timer? _recheckTimer;
  int _recheckAttempts = 0;
  bool _checkoutOpen = false;
  final pendingCheckout = Observable<String?>(null);

  late final AuthController _authController = ref.read(authControllerProvider);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  StreamSubscription? _stockSubscription;
  FieldSubscription? _cartWorker;

  // Observable list of cart items
  ObservableList<CartItem> cartItems = ObservableList(<CartItem>[]);

  // Track current route to show/hide global cart snackbar
  Observable<String> currentRoute = Observable('');

  final Box _cartBox = Hive.box('cart_box');

  // Processing state to prevent double taps
  Observable<bool> isProcessingOrder = Observable(false);

  // Wallet State
  Observable<int> walletBalancePaise = Observable(0);
  Observable<bool> useWallet = Observable(true);

  // Coupon State
  Observable<String> appliedCoupon = Observable('');
  Observable<CouponModel?> activeCouponModel = Observable<CouponModel?>(null);
  Observable<bool> isApplyingCoupon = Observable(false);

  // Delivery Instruction
  Observable<String> deliveryInstruction = Observable('');

  // Computed values
  double get subtotal {
    return cartItems.fold(
      0,
      (accSum, item) => accSum + (item.price * item.count),
    );
  }

  double get deliveryFee {
    // Free delivery above ₹300
    return subtotal > 300 ? 0 : 30;
  }

  double get discount {
    if (activeCouponModel.value != null) {
      double applicableSubtotal = _calculateApplicableSubtotal(
        activeCouponModel.value!,
      );
      if (applicableSubtotal == 0) return 0;

      double calculatedDiscount = 0;
      if (activeCouponModel.value!.discountType == 'percentage') {
        calculatedDiscount =
            applicableSubtotal * (activeCouponModel.value!.discountValue / 100);
      } else {
        // flat/fixed
        calculatedDiscount = activeCouponModel.value!.discountValue;
      }
      return calculatedDiscount > applicableSubtotal
          ? applicableSubtotal
          : calculatedDiscount;
    }

    return 0;
  }

  double get couponDiscountValue => discount;

  double get autoDiscountValue {
    return 0;
  }

  double get total {
    return subtotal + deliveryFee - discount;
  }

  // Wallet getters
  double get walletBalanceAmount => walletBalancePaise.value / 100.0;

  int get appliedWalletPaise {
    if (!useWallet.value || walletBalancePaise.value <= 0) return 0;
    final totalPaise = (total * 100).round();
    return walletBalancePaise.value.clamp(0, totalPaise);
  }

  double get appliedWalletAmount => appliedWalletPaise / 100.0;

  int get payablePaise => ((total * 100).round() - appliedWalletPaise).clamp(
    0,
    (total * 100).round(),
  );

  double get payableAmount => payablePaise / 100.0;

  bool get isFullyPaidByWallet => appliedWalletPaise > 0 && payablePaise == 0;

  Future<void> fetchWalletBalance() async {
    try {
      final user = _authController.firebaseUser.value;
      if (user == null) {
        walletBalancePaise.value = 0;
        return;
      }
      final result = await FirebaseFunctions.instance
          .httpsCallable('getDebugWallet')
          .call();
      if (result.data != null && result.data['balancePaise'] != null) {
        walletBalancePaise.value = (result.data['balancePaise'] as num).toInt();
      }
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  int get totalItemCount {
    return cartItems.length;
  }

  String get currentOrigin {
    return ref.read(homepageControllerProvider).currentOrigin;
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
        CustomSnackBar.show(
          'Invalid Coupon',
          'The coupon code you entered is not valid.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
      CustomSnackBar.show(
        'Cannot Apply',
        validationError,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
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
      if (userOrders.count != null &&
          userOrders.count! >= coupon.maxUsesPerUser!) {
        CustomSnackBar.show(
          'Limit Exceeded',
          'You have already used this coupon maximum times.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    activeCouponModel.value = coupon;
    appliedCoupon.value = coupon.code;

    CustomSnackBar.show(
      'Coupon Applied',
      'Discount applied successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.top,
    );
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

    if (coupon.totalUsageLimit != null &&
        coupon.currentUsageCount >= coupon.totalUsageLimit!) {
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
    if (coupon.applyTo == 'all' ||
        (coupon.applicableCategory == null &&
            coupon.applicableProduct == null)) {
      return subtotal;
    }

    double appSubtotal = 0;
    for (var item in cartItems) {
      bool isApplicable = false;

      if (coupon.applicableCategory != null &&
          item.category == coupon.applicableCategory) {
        isApplicable = true;
      } else if (coupon.applicableProduct != null &&
          item.id.split('_').first == coupon.applicableProduct) {
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
    CustomSnackBar.show(
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
      if (ref.exists(userActivityControllerProvider)) {
        ref.read(userActivityControllerProvider).trackAddToCart(product);
      }
    } catch (e) {
      debugPrint("Error tracking cart activity: $e");
    }

    if (_authController.firebaseUser.value == null) {
      AppNavigator.toNamed(AppRoutes.loginScreen);
      CustomSnackBar.show(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: AppNavigator.theme.primaryColor,
        colorText: Colors.white,
      );
      return false;
    }

    // Check if item is in stock at all
    if (!product.inStock || product.stockCount <= 0) {
      CustomSnackBar.show(
        'Out of Stock',
        'Sorry, ${product.title} is currently out of stock.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Use product ID if available, otherwise use title
    String productId = product.id ?? product.title;

    // If product has variations, append the first variation's ID or unit to match ProductDetails behavior
    if (product.hasVariations &&
        product.variations != null &&
        product.variations!.isNotEmpty) {
      if (!productId.contains('_')) {
        final v = product.variations!.first;
        final vId = v.id ?? "${v.unitValue}${v.unit}";
        productId = '${productId}_$vId';
      }
    }

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
        CustomSnackBar.show(
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
      AppNavigator.toNamed(AppRoutes.loginScreen);
      CustomSnackBar.show(
        'Login Required',
        'Please login to add items to your cart.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: AppNavigator.theme.primaryColor,
        colorText: Colors.white,
      );
      return false;
    }

    // Check if item is in stock
    if (!item.inStock || item.availableStock <= 0) {
      CustomSnackBar.show(
        'Out of Stock',
        'Sorry, ${item.name} is currently out of stock.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final existingIndex = cartItems.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      if (cartItems[existingIndex].count + 1 >
          cartItems[existingIndex].availableStock) {
        CustomSnackBar.show(
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
        CustomSnackBar.show(
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
      } else if (cartItems[index].count == 1) {
        cartItems.removeAt(index);
        cartItems.refresh();
        _saveToHive();
      }
    }
  }

  void clearCart() {
    cartItems.clear();
    deliveryInstruction.value = '';
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

    observeField(_authController.firebaseUser, (user) {
      _loadFromHive();
      fetchWalletBalance();
      checkPendingPayment();
    });

    _loadFromHive();
    fetchWalletBalance();
    _startStockListener();
    _initializeRazorpay();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => checkPendingPayment());
  }

  void _startStockListener() {
    // Listen to changes in cartItems to restart stock synchronization if IDs change
    _cartWorker = observeField(cartItems, (List<CartItem> items) {
      _updateStockSubscription(items);
      _validateActiveCoupon();
    });

    // Initial setup
    _updateStockSubscription(cartItems);
    _validateActiveCoupon();
  }

  void _validateActiveCoupon() {
    if (activeCouponModel.value != null) {
      final validationError = getCouponValidation(activeCouponModel.value!);
      if (validationError != null) {
        appliedCoupon.value = '';
        activeCouponModel.value = null;

        CustomSnackBar.show(
          'Coupon Removed',
          'Cart no longer meets requirements: $validationError',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  List<String> _currentListeningIds = [];

  void _updateStockSubscription(List<CartItem> items) {
    if (items.isEmpty) {
      _stockSubscription?.cancel();
      _currentListeningIds = [];
      return;
    }

    final productIds = items
        .map((item) => item.id.split('_').first)
        .toSet()
        .toList();

    // Prevent rebuilding the stream if the required product IDs haven't changed.
    if (productIds.length == _currentListeningIds.length &&
        productIds.every((id) => _currentListeningIds.contains(id))) {
      return;
    }

    _stockSubscription?.cancel();
    _currentListeningIds = productIds;

    // Firestore whereIn limit is 30. If cart > 30, we'd need chunks.
    // For this app, 30 is likely sufficient.
    final limitedIds = productIds.take(30).toList();

    _stockSubscription = _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: limitedIds)
        .snapshots()
        .listen((snapshot) {
          bool changed = false;

          final fetchedIds = snapshot.docs.map((doc) => doc.id).toList();
          final deletedIds = limitedIds
              .where((id) => !fetchedIds.contains(id))
              .toList();

          if (deletedIds.isNotEmpty) {
            cartItems.removeWhere((item) {
              final baseId = item.id.split('_').first;
              return deletedIds.contains(baseId);
            });
            changed = true;
          }

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final productId = doc.id;

            // Handle variations: find all cart items matching this base product
            for (int index = 0; index < cartItems.length; index++) {
              final cartItemId = cartItems[index].id;
              final baseId = cartItemId.split('_').first;

              if (baseId == productId) {
                double freshPrice = (data['price'] ?? 0).toDouble();
                int freshStock = data['stockCount'] != null
                    ? (data['stockCount']).toInt()
                    : 0; // Strict tracking
                bool freshInStock = (data['inStock'] ?? true) && freshStock > 0;

                // If this cart item is a variation, extract specific price/stock
                if (cartItemId.contains('_') &&
                    data['hasVariations'] == true &&
                    data['variations'] != null) {
                  final variationId = cartItemId.substring(
                    cartItemId.indexOf('_') + 1,
                  );
                  final variationsList = data['variations'] as List;
                  final variationData = variationsList.firstWhere((v) {
                    final vId = v['id']?.toString();
                    if (vId != null && vId == variationId) return true;

                    // Fallback for null IDs: match by unitValue+unit
                    final altId = "${v['unitValue'] ?? ''}${v['unit'] ?? ''}";
                    if (altId == variationId) return true;

                    // Legacy cart items might just have 'null'
                    if (vId == null && variationId == 'null') return true;

                    return false;
                  }, orElse: () => null);

                  if (variationData != null) {
                    freshPrice = (variationData['price'] ?? 0).toDouble();
                    freshStock = variationData['stockCount'] != null
                        ? (variationData['stockCount']).toInt()
                        : 0; // Strict tracking
                    freshInStock =
                        (variationData['inStock'] ?? true) && freshStock > 0;
                  } else {
                    freshInStock = false;
                    freshStock = 0;
                  }
                }

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
    _checkoutWatchdog?.cancel();
    _recheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    _stockSubscription?.cancel();
    _cartWorker?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAttempts = 0;
      unawaited(checkPendingPayment());
    }
  }

  Future<String?> checkPendingPayment({
    PaymentSuccessResponse? response,
    bool showStatus = false,
  }) async {
    if (isClosed) return null;
    final existing = _statusCheck;
    if (existing != null) return existing;
    final uid = _authController.firebaseUser.value?.uid;
    final orderId = uid == null ? null : _checkout.pendingOrder(uid);
    pendingCheckout.value = orderId;
    if (uid == null || orderId == null) return null;
    final check = _resolvePending(uid, orderId, response, showStatus);
    _statusCheck = check;
    try {
      final status = await check;
      if ((status == null ||
              status == 'pending' ||
              status == 'refund_pending') &&
          _authController.firebaseUser.value?.uid == uid &&
          pendingCheckout.value == orderId &&
          _recheckAttempts < 5) {
        _recheckTimer?.cancel();
        final delay = Duration(seconds: 4 << _recheckAttempts++);
        _recheckTimer = Timer(delay, () => unawaited(checkPendingPayment()));
      }
      return status;
    } finally {
      _statusCheck = null;
    }
  }

  Future<String?> _resolvePending(
    String uid,
    String orderId,
    PaymentSuccessResponse? response,
    bool showStatus,
  ) async {
    try {
      String status;
      if (response != null) {
        try {
          status = await _checkout.verify(
            orderId,
            response.paymentId,
            response.orderId,
            response.signature,
          );
        } on FirebaseFunctionsException {
          status = await _checkout.status(orderId);
        }
      } else {
        status = await _checkout.status(orderId);
      }
      if (_authController.firebaseUser.value?.uid != uid) return status;
      switch (status) {
        case 'confirmed':
          _recheckTimer?.cancel();
          pendingCheckout.value = null;
          _checkoutWatchdog?.cancel();
          _checkoutOpen = false;
          isProcessingOrder.value = false;
          if (_checkout.cartMatches(uid, _cartFingerprint())) clearCart();
          await _checkout.finish(uid);
          unawaited(fetchWalletBalance());
          unawaited(ref.read(ordersControllerProvider).loadOrders());
          ref.read(bottomBarControllerProvider).changePage(3);
          AppNavigator.offAllNamed(
            AppRoutes.mainLayout,
            arguments: {
              'showSuccessPopup': true,
              'orderId': orderId,
              'orderType': 'Online',
              'paymentId': response?.paymentId,
            },
          );
        case 'refunded':
          await _checkout.finish(uid);
          pendingCheckout.value = null;
          CustomSnackBar.info(
            'Refund processed',
            'Razorpay processed the refund for order $orderId.',
          );
        case 'refund_pending':
        case 'refund_review':
          if (showStatus) {
            CustomSnackBar.info(
              'Refund status',
              status == 'refund_review'
                  ? 'Contact support with order $orderId so we can check your refund.'
                  : 'Order $orderId could not be fulfilled. Your refund is pending.',
            );
          }
        case 'pending':
          if (showStatus) {
            CustomSnackBar.info(
              'Payment confirmation pending',
              'We are checking order $orderId. Use Check payment status if you were charged.',
            );
          }
      }
      return status;
    } catch (error) {
      debugPrint('Checkout status could not be checked: $error');
      if (showStatus) {
        CustomSnackBar.info(
          'Payment status unavailable',
          'Check your connection and try Check payment status for order $orderId.',
        );
      }
      return null;
    }
  }

  Future<void> closeUnpaidCheckout() async {
    if (isProcessingOrder.value || _statusCheck != null) return;
    final uid = _authController.firebaseUser.value?.uid;
    final id = pendingCheckout.value;
    if (uid == null || id == null) return;
    isProcessingOrder.value = true;
    try {
      final status = await _checkout.detach(id);
      if (status == 'detached') {
        await _checkout.finish(uid);
        pendingCheckout.value = null;
      } else {
        await checkPendingPayment(showStatus: true);
      }
    } catch (error) {
      CustomSnackBar.info(
        'Checkout status unavailable',
        'Try again when you are connected. Your payment reference is still saved.',
      );
    } finally {
      isProcessingOrder.value = false;
    }
  }

  bool get hasPendingCheckout {
    return pendingCheckout.value != null;
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _checkoutWatchdog?.cancel();
    _checkoutOpen = false;
    try {
      await checkPendingPayment(response: response, showStatus: true);
    } finally {
      isProcessingOrder.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _checkoutWatchdog?.cancel();
    _checkoutOpen = false;
    isProcessingOrder.value = false;
    unawaited(checkPendingPayment(showStatus: true));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    CustomSnackBar.info(
      'External wallet',
      'Continue payment in ${response.walletName}.',
    );
  }

  Future<void> processPayment() async {
    if (isProcessingOrder.value) return;
    isProcessingOrder.value = true;

    final user = _authController.firebaseUser.value;
    if (user == null) {
      isProcessingOrder.value = false;
      AppNavigator.toNamed(AppRoutes.loginScreen);
      return;
    }

    if (hasPendingCheckout) {
      final status = await checkPendingPayment(showStatus: true);
      if (status != 'pending') {
        isProcessingOrder.value = false;
        return;
      }
    }

    // Step 0: Validate Service Area
    final resolved = _resolveDeliveryAddressData();
    if (!_validateServiceArea(resolved)) {
      isProcessingOrder.value = false;
      return;
    }

    if (!ref.exists(slotSelectionControllerProvider) ||
        ref
            .read(slotSelectionControllerProvider)
            .selectedSlotId
            .value
            .isEmpty) {
      isProcessingOrder.value = false;
      CustomSnackBar.show(
        'Missing Information',
        'Please select a delivery slot before making a payment.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Step 1: Validate prices and stock first
    AppNavigator.dialog(
      Center(
        child: CircularProgressIndicator(
          color: AppNavigator.theme.primaryColor,
        ),
      ),
      barrierDismissible: false,
    );
    await validateCartItems();
    AppNavigator.back();

    // Check if any items became out of stock
    if (cartItems.any((item) => !item.inStock)) {
      CustomSnackBar.show(
        'Out of Stock',
        'Some items in your cart are now out of stock. Please review.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isProcessingOrder.value = false;
      return;
    }

    await fetchWalletBalance();

    if (isFullyPaidByWallet && !hasPendingCheckout) {
      try {
        final orderId = await placeOrder(
          paymentStatus: 'paid',
          orderType: 'Wallet',
          walletAppliedPaise: appliedWalletPaise,
        );
        if (orderId != null) {
          clearCart();
          await fetchWalletBalance();
          ref.read(bottomBarControllerProvider).changePage(3);
          AppNavigator.offAllNamed(
            AppRoutes.mainLayout,
            arguments: {
              'showSuccessPopup': true,
              'orderId': orderId,
              'orderType': 'Wallet',
            },
          );
        }
      } finally {
        isProcessingOrder.value = false;
      }
      return;
    }

    try {
      final order = _buildOrder(
        orderType: 'Online',
        walletAppliedPaise: appliedWalletPaise,
      );
      final session = await _checkout.start(
        user.uid,
        order.toJson(),
        _cartFingerprint(),
      );
      _recheckAttempts = 0;
      pendingCheckout.value = session.orderId;
      if (session.amount != payablePaise) {
        CustomSnackBar.warning(
          'Total changed',
          'Review your cart and try again.',
        );
        return;
      }
      _checkoutOpen = true;
      _checkoutWatchdog = Timer(const Duration(minutes: 3), () {
        _checkoutOpen = false;
        isProcessingOrder.value = false;
        unawaited(checkPendingPayment(showStatus: true));
      });
      _razorpay.open({
        'key': session.keyId,
        'order_id': session.gatewayOrderId,
        'amount': session.amount,
        'currency': 'INR',
        'name': 'Kissan Fresh',
        'description': 'Order Payment',
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {
          'contact': user.phoneNumber ?? '',
          'email': user.email ?? '',
        },
        'external': {
          'wallets': ['paytm'],
        },
      });
    } catch (error) {
      _checkoutOpen = false;
      _checkoutWatchdog?.cancel();
      CustomSnackBar.error(
        'Unable to open checkout',
        error is FirebaseFunctionsException
            ? (error.message ?? 'Please try again.')
            : 'Please try again.',
      );
    } finally {
      if (!_checkoutOpen) isProcessingOrder.value = false;
    }
  }

  String _cartFingerprint() => jsonEncode(
    cartItems.map((item) => [item.id, item.count, item.price]).toList(),
  );

  OrderModel _buildOrder({
    String paymentStatus = 'pending',
    required String orderType,
    required int walletAppliedPaise,
  }) {
    final user = _authController.firebaseUser.value;
    if (user == null) throw Exception('User not logged in');

    final String orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Resolve delivery address from multiple sources
    final resolved = _resolveDeliveryAddressData();

    String slotId = '';
    if (ref.exists(slotSelectionControllerProvider)) {
      slotId = ref.read(slotSelectionControllerProvider).selectedSlotId.value;
    }
    if (slotId.isEmpty) {
      throw Exception('Delivery slot not selected.');
    }

    return OrderModel(
      id: '',
      userId: user.uid,
      orderNumber: orderNumber,
      items: cartItems
          .map(
            (item) => OrderItem(
              productId: item.id
                  .split('_')
                  .first, // Ensure backend gets the base productId
              variationId: item.id.contains('_')
                  ? item.id.substring(item.id.indexOf('_') + 1)
                  : null,
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
      slotId: slotId,
      couponCode: appliedCoupon.value.isEmpty ? null : appliedCoupon.value,
      deliveryInstruction: deliveryInstruction.value.isEmpty
          ? null
          : deliveryInstruction.value,
      walletAppliedPaise: walletAppliedPaise,
    );
  }

  Future<String?> placeOrder({
    String paymentStatus = 'pending',
    required String orderType,
    int walletAppliedPaise = 0,
  }) async {
    try {
      final order = _buildOrder(
        paymentStatus: paymentStatus,
        orderType: orderType,
        walletAppliedPaise: walletAppliedPaise,
      );
      final orderId = await _checkout.placeDirectOrder(
        order.userId,
        order.toJson(),
      );
      clearCart();
      return orderId;
    } catch (error) {
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      CustomSnackBar.error(
        'Order failed',
        error is FirebaseFunctionsException
            ? (error.message ?? 'Please try again.')
            : 'Please try again.',
      );
      unawaited(validateCartItems());
    }
    return null;
  }

  /// Helper to check if the resolved address is within the service area (30km)
  bool _validateServiceArea(ResolvedAddress resolved) {
    final locationService = ref.read(locationServiceProvider);

    // If we have coordinates, use the precise distance check
    if (resolved.latitude != null && resolved.longitude != null) {
      final isServiceable = locationService.isWithinServiceArea(
        resolved.latitude,
        resolved.longitude,
      );

      if (!isServiceable) {
        CustomSnackBar.show(
          'Service Unavailable',
          'We are not in your area yet. Currently, we only serve Chattrapati Sambhaji Nagar.',
          snackPosition: SnackPosition.bottom,
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
      CustomSnackBar.show(
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

    // Priority 1: LocationService (GPS-detected or manually updated detailed address)
    try {
      if (ref.exists(locationServiceProvider)) {
        final loc = ref.read(locationServiceProvider);
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
        return ResolvedAddress(address: addr, latitude: lat, longitude: lng);
      }
    } catch (_) {}

    return ResolvedAddress(address: 'Address not available');
  }

  // Retained as a recovery hook for payment providers that cannot atomically
  // roll back inventory and payment state.
  // ignore: unused_element
  /// Place a Cash on Delivery order without Razorpay.
  Future<void> placeCodOrder() async {
    if (isProcessingOrder.value) return;
    isProcessingOrder.value = true;

    final user = _authController.firebaseUser.value;
    if (user == null) {
      isProcessingOrder.value = false;
      AppNavigator.toNamed(AppRoutes.loginScreen);
      return;
    }

    if (hasPendingCheckout) {
      await checkPendingPayment(showStatus: true);
      isProcessingOrder.value = false;
      return;
    }

    // Step 0: Validate Service Area
    final resolved = _resolveDeliveryAddressData();
    if (!_validateServiceArea(resolved)) {
      isProcessingOrder.value = false;
      return;
    }

    if (!ref.exists(slotSelectionControllerProvider) ||
        ref
            .read(slotSelectionControllerProvider)
            .selectedSlotId
            .value
            .isEmpty) {
      isProcessingOrder.value = false;
      CustomSnackBar.show(
        'Missing Information',
        'Please select a delivery slot before making an order.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate stock first
    AppNavigator.dialog(
      Center(
        child: CircularProgressIndicator(
          color: AppNavigator.theme.primaryColor,
        ),
      ),
      barrierDismissible: false,
    );
    await validateCartItems();
    AppNavigator.back();

    if (cartItems.any((item) => !item.inStock)) {
      CustomSnackBar.show(
        'Out of Stock',
        'Some items in your cart are now out of stock. Please review.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isProcessingOrder.value = false;
      return;
    }

    // Show loading
    AppNavigator.dialog(
      Center(
        child: CircularProgressIndicator(
          color: AppNavigator.theme.primaryColor,
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final serverOrderId = await placeOrder(
        paymentStatus: 'pending',
        orderType: 'COD',
        walletAppliedPaise: appliedWalletPaise,
      );

      if (AppNavigator.isDialogOpen) AppNavigator.back();

      if (serverOrderId != null) {
        fetchWalletBalance();
        if (ref.exists(ordersControllerProvider)) {
          ref.read(ordersControllerProvider).loadOrders();
        }

        ref.read(bottomBarControllerProvider).changePage(3);
        // Navigate to My Orders with success popup flag
        AppNavigator.offAllNamed(
          AppRoutes.mainLayout,
          arguments: {
            'showSuccessPopup': true,
            'orderId': serverOrderId,
            'orderType': 'COD',
          },
        );
      }
    } catch (e) {
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      debugPrint('Error in placeCodOrder: $e');
      CustomSnackBar.show(
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
      // Get unique base IDs for querying Firebase (stripping variation extensions)
      final List<String> baseIds = cartItems
          .map((e) => e.id.split('_').first)
          .toSet()
          .toList();

      // Process in chunks of 30 due to whereIn limits
      for (int i = 0; i < baseIds.length; i += 30) {
        final chunk = baseIds.skip(i).take(30).toList();

        final querySnap = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final docMap = {for (var doc in querySnap.docs) doc.id: doc.data()};

        for (int j = 0; j < cartItems.length; j++) {
          var cartItem = cartItems[j];
          final baseId = cartItem.id.split('_').first;

          if (!chunk.contains(baseId)) continue;

          if (docMap.containsKey(baseId)) {
            final data = docMap[baseId]!;

            double freshPrice = (data['price'] ?? 0).toDouble();
            int freshStockCount = data['stockCount'] != null
                ? (data['stockCount']).toInt()
                : 0; // Strict tracking
            bool freshStockStatus =
                (data['inStock'] ?? true) && freshStockCount > 0;

            // Handle variation specific stock if applicable
            if (cartItem.id.contains('_') &&
                data['hasVariations'] == true &&
                data['variations'] != null) {
              final variationId = cartItem.id.substring(
                cartItem.id.indexOf('_') + 1,
              );
              final variationsList = data['variations'] as List;
              final variationData = variationsList.firstWhere((v) {
                final vId = v['id']?.toString();
                if (vId != null && vId == variationId) return true;
                final altId = "${v['unitValue'] ?? ''}${v['unit'] ?? ''}";
                if (altId == variationId) return true;
                if (vId == null && variationId == 'null') return true;
                return false;
              }, orElse: () => null);

              if (variationData != null) {
                freshPrice = (variationData['price'] ?? 0).toDouble();
                freshStockCount = variationData['stockCount'] != null
                    ? (variationData['stockCount']).toInt()
                    : 0; // Strict tracking
                freshStockStatus =
                    (variationData['inStock'] ?? true) && freshStockCount > 0;
              } else {
                freshStockStatus = false;
                freshStockCount = 0;
              }
            }

            if (cartItem.price != freshPrice ||
                cartItem.inStock != freshStockStatus ||
                cartItem.availableStock != freshStockCount) {
              cartItem.price = freshPrice;
              cartItem.inStock = freshStockStatus;
              cartItem.availableStock = freshStockCount;

              if (cartItem.count > freshStockCount && freshStockCount >= 0) {
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
      final user = _authController.firebaseUser.value;
      if (user == null) {
        cartItems.clear();
        return;
      }

      final String cartKey = 'cart_items_list_${user.uid}';
      final String timestampKey = 'cart_timestamp_${user.uid}';

      final savedData = _cartBox.get(cartKey);
      final savedTimestamp = _cartBox.get(timestampKey);

      if (savedData != null) {
        if (savedTimestamp != null) {
          final DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(
            savedTimestamp,
          );
          final Duration difference = DateTime.now().difference(lastUpdated);
          if (difference.inDays >= 7) {
            _cartBox.delete(cartKey);
            _cartBox.delete(timestampKey);
            cartItems.clear();
            return;
          }
        }

        List<dynamic> itemsList = jsonDecode(savedData);
        cartItems.value = itemsList
            .map((item) => CartItem.fromJson(item))
            .toList();
      } else {
        cartItems.clear();
      }
    } catch (e) {
      CustomSnackBar.show('Cart Error', 'Failed to load local cart items.');
    }
  }

  void _saveToHive() {
    try {
      final user = _authController.firebaseUser.value;
      if (user == null) return;

      final String cartKey = 'cart_items_list_${user.uid}';
      final String timestampKey = 'cart_timestamp_${user.uid}';

      List<Map<String, dynamic>> jsonData = cartItems
          .map((item) => item.toJson())
          .toList();
      _cartBox.put(cartKey, jsonEncode(jsonData));
      _cartBox.put(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error saving cart to Hive: $e");
    }
  }
}

class ResolvedAddress {
  final String address;
  final double? latitude;
  final double? longitude;

  ResolvedAddress({required this.address, this.latitude, this.longitude});
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

final cartControllerProvider = Provider(
  (ref) => startController(ref, CartController(ref)),
);
