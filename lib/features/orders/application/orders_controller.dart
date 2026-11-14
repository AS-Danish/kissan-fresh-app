import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:hive/hive.dart';
import 'package:kissanfresh/features/orders/domain/order_model.dart';
import 'package:kissanfresh/features/orders/domain/rider_model.dart';
import 'package:kissanfresh/features/delivery/domain/slot_model.dart';
import 'package:kissanfresh/features/auth/application/auth_controller.dart';
import 'package:kissanfresh/core/services/network_service.dart';

class OrdersController extends FeatureController {
  final Ref ref;

  OrdersController(this.ref);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthController _authController = ref.read(authControllerProvider);
  late Box _ordersBox;

  ObservableList<OrderModel> orders = ObservableList(<OrderModel>[]);
  Observable<bool> isLoading = Observable(false);

  // Filtering
  Observable<String> selectedFilter = Observable('Current Month');
  final List<String> filterOptions = [
    'Current Month',
    'Past 3 Months',
    'Past 6 Months',
    '2024',
    '2023',
    'All Time',
  ];

  // Caches to avoid redundant Firestore reads
  final Map<String, RiderModel> _riderCache = {};
  final Map<String, SlotModel> _slotCache = {};

  // Filter orders
  List<OrderModel> get activeOrders => orders
      .where(
        (order) =>
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled,
      )
      .toList();

  List<OrderModel> get completedOrders =>
      orders.where((order) => order.status == OrderStatus.delivered).toList();

  List<OrderModel> get cancelledOrders =>
      orders.where((order) => order.status == OrderStatus.cancelled).toList();

  @override
  void onInit() {
    super.onInit();
    _ordersBox = Hive.box('orders_cache');
    _loadOrdersFromCache();
    loadOrders();

    // Watch for filter changes
    observeField(selectedFilter, (_) => loadOrders());
    observeField(_authController.firebaseUser, (_) {
      orders.clear();
      _loadOrdersFromCache();
      loadOrders();
    });
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

  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  int _loadGeneration = 0;
  int _snapshotGeneration = 0;

  @override
  void onClose() {
    _loadGeneration++;
    _ordersSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadOrders() async {
    final generation = ++_loadGeneration;
    await _ordersSubscription?.cancel();
    if (generation != _loadGeneration) return;
    final user = _authController.firebaseUser.value;
    if (user == null) {
      orders.clear();
      isLoading.value = false;
      return;
    }

    final connected = await NetworkService.isConnected();
    if (generation != _loadGeneration) return;
    if (!connected) {
      NetworkService.showNoInternetSnackbar();
      isLoading.value = false;
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
        query = query.where(
          'orderDate',
          isGreaterThanOrEqualTo: startOfMonth.toIso8601String(),
        );
      } else if (selectedFilter.value == 'Past 3 Months') {
        DateTime threeMonthsAgo = now.subtract(const Duration(days: 90));
        query = query.where(
          'orderDate',
          isGreaterThanOrEqualTo: threeMonthsAgo.toIso8601String(),
        );
      } else if (selectedFilter.value == 'Past 6 Months') {
        DateTime sixMonthsAgo = now.subtract(const Duration(days: 180));
        query = query.where(
          'orderDate',
          isGreaterThanOrEqualTo: sixMonthsAgo.toIso8601String(),
        );
      } else if (selectedFilter.value == '2024') {
        DateTime startOfYear = DateTime(2024, 1, 1);
        DateTime endOfYear = DateTime(2024, 12, 31, 23, 59, 59);
        query = query
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: startOfYear.toIso8601String(),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: endOfYear.toIso8601String(),
            );
      } else if (selectedFilter.value == '2023') {
        DateTime startOfYear = DateTime(2023, 1, 1);
        DateTime endOfYear = DateTime(2023, 12, 31, 23, 59, 59);
        query = query
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: startOfYear.toIso8601String(),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: endOfYear.toIso8601String(),
            );
      }

      _ordersSubscription = query
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) async {
              if (generation != _loadGeneration) return;
              final snapshotGeneration = ++_snapshotGeneration;
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

              if (generation != _loadGeneration ||
                  snapshotGeneration != _snapshotGeneration) {
                return;
              }
              orders.value = fetchedOrders;

              _saveOrdersToCache();
              isLoading.value = false;
            },
            onError: (e) {
              if (generation != _loadGeneration) return;
              debugPrint('Firestore Stream Error: $e');
              isLoading.value = false;
              if (e.toString().contains('failed-precondition')) {
                CustomSnackBar.show(
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
    CustomSnackBar.show(
      'Reorder',
      'Adding items to cart...',
      snackPosition: SnackPosition.bottom,
      backgroundColor: AppNavigator.theme.primaryColor,
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

final ordersControllerProvider = Provider(
  (ref) => startController(ref, OrdersController(ref)),
);
