class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final double subtotal;
  final double discount;
  final double couponDiscount;
  final double deliveryFee;
  final DateTime orderDate;
  final DateTime? deliveredDate;
  final OrderStatus status;
  final String? paymentId;
  final String deliveryAddress;
  final String paymentStatus;
  final String orderType;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    this.paymentId,
    required this.items,
    required this.totalAmount,
    required this.subtotal,
    this.discount = 0.0,
    this.couponDiscount = 0.0,
    this.deliveryFee = 0.0,
    required this.orderDate,
    this.deliveredDate,
    required this.status,
    required this.deliveryAddress,
    this.paymentStatus = 'paid',
    this.orderType = 'Online',
  });

  bool get isDelivered => status == OrderStatus.delivered;

  String get statusText {
    switch (status) {
      case OrderStatus.processing:
        return 'PROCESSING';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'paymentId': paymentId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'discount': discount,
      'couponDiscount': couponDiscount,
      'deliveryFee': deliveryFee,
      'orderDate': orderDate.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'deliveryAddress': deliveryAddress,
      'paymentStatus': paymentStatus,
      'orderType': orderType,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      paymentId: json['paymentId'],
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      couponDiscount: (json['couponDiscount'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      orderDate: DateTime.parse(json['orderDate']),
      deliveredDate: json['deliveredDate'] != null ? DateTime.parse(json['deliveredDate']) : null,
      status: OrderStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => OrderStatus.processing,
      ),
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'paid',
      orderType: json['orderType'] ?? 'Online',
    );
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String image;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.title,
    required this.image,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'image': image,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

enum OrderStatus {
  processing,
  outForDelivery,
  delivered,
  cancelled,
}