import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/order_model.dart';
import '../model/rider_model.dart';
import '../model/slot_model.dart';
import 'auth_controller.dart';

class OrdersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  late Box _ordersBox;

  RxList<OrderModel> orders = <OrderModel>[].obs;
  RxBool isLoading = false.obs;
  
  // Filtering
  RxString selectedFilter = 'Current Month'.obs;
  final List<String> filterOptions = [
    'Current Month',
    'Past 3 Months',
    'Past 6 Months',
    '2024',
    '2023',
    'All Time'
  ];

  // Caches to avoid redundant Firestore reads
  final Map<String, RiderModel> _riderCache = {};
  final Map<String, SlotModel> _slotCache = {};

  // Filter orders
  RxList<OrderModel> get activeOrders => orders
      .where(
        (order) =>
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled,
      )
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
    
    // Watch for filter changes
    ever(selectedFilter, (_) => loadOrders());
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
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
      Query query = _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true);

      // Apply date filter
      DateTime now = DateTime.now();
      if (selectedFilter.value == 'Current Month') {
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        query = query.where('orderDate', isGreaterThanOrEqualTo: startOfMonth.toIso8601String());
      } else if (selectedFilter.value == 'Past 3 Months') {
        DateTime threeMonthsAgo = now.subtract(const Duration(days: 90));
        query = query.where('orderDate', isGreaterThanOrEqualTo: threeMonthsAgo.toIso8601String());
      } else if (selectedFilter.value == 'Past 6 Months') {
        DateTime sixMonthsAgo = now.subtract(const Duration(days: 180));
        query = query.where('orderDate', isGreaterThanOrEqualTo: sixMonthsAgo.toIso8601String());
      } else if (selectedFilter.value == '2024') {
        DateTime startOfYear = DateTime(2024, 1, 1);
        DateTime endOfYear = DateTime(2024, 12, 31, 23, 59, 59);
        query = query.where('orderDate', isGreaterThanOrEqualTo: startOfYear.toIso8601String())
                     .where('orderDate', isLessThanOrEqualTo: endOfYear.toIso8601String());
      } else if (selectedFilter.value == '2023') {
        DateTime startOfYear = DateTime(2023, 1, 1);
        DateTime endOfYear = DateTime(2023, 12, 31, 23, 59, 59);
        query = query.where('orderDate', isGreaterThanOrEqualTo: startOfYear.toIso8601String())
                     .where('orderDate', isLessThanOrEqualTo: endOfYear.toIso8601String());
      }

      query
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) async {
              final List<OrderModel> fetchedOrders = [];

              for (var doc in snapshot.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId = doc.id;
                  OrderModel order = OrderModel.fromJson({
                    ...data,
                    'id': orderId,
                  });

                  // Fetch rider details if available
                  if (order.riderId != null && order.riderId!.isNotEmpty) {
                    order = order.copyWith(
                      rider: await _fetchRiderDetails(order.riderId!),
                    );
                  }

                  // Fetch slot details if available
                  if (order.slotId != null && order.slotId!.isNotEmpty) {
                    order = order.copyWith(
                      slot: await _fetchSlotDetails(order.slotId!),
                    );
                  }

                  fetchedOrders.add(order);
                } catch (e) {
                  debugPrint('Error parsing order ${doc.id}: $e');
                }
              }

              orders.value = fetchedOrders;

              _saveOrdersToCache();
              isLoading.value = false;
            },
            onError: (e) {
              debugPrint('Firestore Stream Error: $e');
              isLoading.value = false;
              if (e.toString().contains('failed-precondition')) {
                Get.snackbar(
                  'Configuration Required',
                  'Firestore needs an index for orders. Please check debug console for the link.',
                  duration: const Duration(seconds: 10),
                );
              }
            },
          );
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
      backgroundColor: const Color(0xFF14B8A6),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<RiderModel?> _fetchRiderDetails(String riderId) async {
    if (_riderCache.containsKey(riderId)) {
      return _riderCache[riderId];
    }

    try {
      final doc = await _firestore.collection('riders').doc(riderId).get();
      if (doc.exists && doc.data() != null) {
        final rider = RiderModel.fromJson(doc.data()!);
        _riderCache[riderId] = rider;
        return rider;
      }
    } catch (e) {
      debugPrint('Error fetching rider $riderId: $e');
    }
    return null;
  }

  Future<SlotModel?> _fetchSlotDetails(String slotId) async {
    if (_slotCache.containsKey(slotId)) {
      return _slotCache[slotId];
    }

    try {
      final doc = await _firestore.collection('slots').doc(slotId).get();
      if (doc.exists && doc.data() != null) {
        final slot = SlotModel.fromJson(doc.data()!, id: doc.id);
        _slotCache[slotId] = slot;
        return slot;
      }
    } catch (e) {
      debugPrint('Error fetching slot $slotId: $e');
    }
    return null;
  }
}
