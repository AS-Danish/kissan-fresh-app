class OrderModel {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final DateTime? deliveredDate;
  final OrderStatus status;
  final String deliveryAddress;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.deliveredDate,
    required this.status,
    required this.deliveryAddress,
  });

  bool get isDelivered => status == OrderStatus.delivered;

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get formattedOrderDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${orderDate.day} ${months[orderDate.month - 1]}, ${orderDate.year}';
  }

  String get formattedDeliveredDate {
    if (deliveredDate == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${deliveredDate!.day} ${months[deliveredDate!.month - 1]}, ${deliveredDate!.year}';
  }
}

class OrderItem {
  final String name;
  final String image;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  outForDelivery,
  delivered,
  cancelled,
}