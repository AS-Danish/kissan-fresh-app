import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/model/order_model.dart';

class OrderTypeBadge extends StatelessWidget {
  final String orderType;

  const OrderTypeBadge({super.key, required this.orderType});

  @override
  Widget build(BuildContext context) {
    final bool isCod = orderType.toUpperCase() == 'COD' ||
        orderType.toUpperCase() == 'CASH ON DELIVERY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCod
            ? const Color(0xFF14B8A6).withOpacity(0.12)
            : const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCod ? Icons.money_rounded : Icons.account_balance_wallet_rounded,
            size: 12,
            color: isCod ? const Color(0xFF14B8A6) : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 4),
          Text(
            isCod ? 'COD' : 'Online',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isCod ? const Color(0xFF14B8A6) : const Color(0xFF6366F1),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  String _getStatusText(OrderStatus status) {
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

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case OrderStatus.processing:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.local_shipping_outlined;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            _getStatusText(status),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
