import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/order_model.dart';
import 'auth_controller.dart';

class OrdersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  late Box _ordersBox;
  
  RxList<OrderModel> orders = <OrderModel>[].obs;
  RxBool isLoading = false.obs;

  // Filter orders
  RxList<OrderModel> get activeOrders => orders
      .where((order) => order.status != OrderStatus.delivered &&
      order.status != OrderStatus.cancelled)
      .toList()
      .obs;

  RxList<OrderModel> get completedOrders => orders
      .where((order) => order.status == OrderStatus.delivered)
      .toList()
      .obs;

  RxList<OrderModel> get cancelledOrders => orders
      .where((order) => order.status == OrderStatus.cancelled)
      .toList()
      .obs;

  @override
  void onInit() {
    super.onInit();
    _ordersBox = Hive.box('orders_cache');
    _loadOrdersFromCache();
    loadOrders();
  }

  void _loadOrdersFromCache() {
    final user = _authController.firebaseUser.value;
    if (user == null) return;

    final cachedData = _ordersBox.get('orders_${user.uid}');
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        orders.value = decoded.map((e) => OrderModel.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading cached orders: $e');
      }
    }
  }

  void _saveOrdersToCache() {
    final user = _authController.firebaseUser.value;
    if (user == null) return;

    final encoded = jsonEncode(orders.map((e) => e.toJson()).toList());
    _ordersBox.put('orders_${user.uid}', encoded);
  }

  Future<void> loadOrders() async {
    final user = _authController.firebaseUser.value;
    if (user == null) {
      orders.clear();
      return;
    }

    if (orders.isEmpty) {
      isLoading.value = true;
    }

    try {
      _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
        orders.value = snapshot.docs
            .map((doc) {
              try {
                return OrderModel.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                debugPrint('Error parsing order ${doc.id}: $e');
                return null;
              }
            })
            .whereType<OrderModel>()
            .toList();
        
        _saveOrdersToCache();
        isLoading.value = false;
      }, onError: (e) {
        debugPrint('Firestore Stream Error: $e');
        isLoading.value = false;
        if (e.toString().contains('failed-precondition')) {
            Get.snackbar(
              'Configuration Required',
              'Firestore needs an index for orders. Please check debug console for the link.',
              duration: const Duration(seconds: 10),
            );
        }
      });
    } catch (e) {
      debugPrint('Error initiating order load: $e');
      isLoading.value = false;
    }
  }

  void reorderItems(OrderModel order) {
    // Implement reorder functionality
    Get.snackbar(
      'Reorder',
      'Adding items to cart...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}