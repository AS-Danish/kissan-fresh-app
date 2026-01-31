import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../model/order_model.dart';

class OrdersController extends GetxController {
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
    loadOrders();
  }

  void loadOrders() {
    isLoading.value = true;

    // Sample orders data
    orders.value = [
      OrderModel(
        id: '1',
        orderNumber: 'ORD20240001',
        items: [
          OrderItem(
            name: 'Fresh Organic Tomatoes',
            image: 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400',
            quantity: 2,
            price: 90.0,
          ),
          OrderItem(
            name: 'Farm Fresh Spinach',
            image: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
            quantity: 1,
            price: 90.0,
          ),
        ],
        totalAmount: 270.0,
        orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        deliveredDate: null,
        status: OrderStatus.outForDelivery,
        deliveryAddress: 'Azam Colony, Roshan Gate',
      ),
      OrderModel(
        id: '2',
        orderNumber: 'ORD20240002',
        items: [
          OrderItem(
            name: 'Organic Carrots',
            image: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400',
            quantity: 1,
            price: 100.0,
          ),
          OrderItem(
            name: 'Fresh Green Beans',
            image: 'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=400',
            quantity: 2,
            price: 60.0,
          ),
        ],
        totalAmount: 220.0,
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        deliveredDate: DateTime.now().subtract(const Duration(days: 2)),
        status: OrderStatus.delivered,
        deliveryAddress: 'Azam Colony, Roshan Gate',
      ),
      OrderModel(
        id: '3',
        orderNumber: 'ORD20240003',
        items: [
          OrderItem(
            name: 'Fresh Organic Potatoes',
            image: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400',
            quantity: 3,
            price: 40.0,
          ),
        ],
        totalAmount: 120.0,
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        deliveredDate: DateTime.now().subtract(const Duration(days: 5)),
        status: OrderStatus.delivered,
        deliveryAddress: 'Azam Colony, Roshan Gate',
      ),
      OrderModel(
        id: '4',
        orderNumber: 'ORD20240004',
        items: [
          OrderItem(
            name: 'Fresh Bell Peppers',
            image: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400',
            quantity: 2,
            price: 80.0,
          ),
          OrderItem(
            name: 'Organic Cucumbers',
            image: 'https://images.unsplash.com/photo-1589927986089-35812378d2a9?w=400',
            quantity: 1,
            price: 50.0,
          ),
        ],
        totalAmount: 210.0,
        orderDate: DateTime.now().subtract(const Duration(hours: 5)),
        deliveredDate: null,
        status: OrderStatus.processing,
        deliveryAddress: 'Azam Colony, Roshan Gate',
      ),
      OrderModel(
        id: '5',
        orderNumber: 'ORD20240005',
        items: [
          OrderItem(
            name: 'Fresh Broccoli',
            image: 'https://images.unsplash.com/photo-1628773822990-202c9cf0e43e?w=400',
            quantity: 1,
            price: 120.0,
          ),
        ],
        totalAmount: 120.0,
        orderDate: DateTime.now().subtract(const Duration(days: 8)),
        deliveredDate: DateTime.now().subtract(const Duration(days: 8)),
        status: OrderStatus.delivered,
        deliveryAddress: 'Azam Colony, Roshan Gate',
      ),
    ];

    isLoading.value = false;
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