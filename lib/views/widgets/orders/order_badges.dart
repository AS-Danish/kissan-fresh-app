import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/model/order_model.dart';

class OrderTypeBadge extends StatelessWidget {
  final String orderType;
  final int walletAppliedPaise;

  const OrderTypeBadge({
    super.key,
    required this.orderType,
    this.walletAppliedPaise = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWalletOnly = orderType.toUpperCase() == 'WALLET';
    final bool isCod =
        orderType.toUpperCase() == 'COD' ||
        orderType.toUpperCase() == 'CASH ON DELIVERY';
    final bool hasWallet = walletAppliedPaise > 0;

    final Color badgeColor = isWalletOnly
        ? const Color(0xFF10B981)
        : (isCod ? Theme.of(context).primaryColor : const Color(0xFF6366F1));

    String badgeLabel;
    if (isWalletOnly) {
      badgeLabel = 'Wallet';
    } else if (hasWallet) {
      badgeLabel = '${isCod ? 'COD' : 'Online'} + Wallet';
    } else {
      badgeLabel = isCod ? 'COD' : 'Online';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalletOnly
                ? Icons.account_balance_wallet_rounded
                : (isCod
                    ? Icons.money_rounded
                    : Icons.payment_rounded),
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeLabel,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
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
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.local_shipping_outlined;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
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
