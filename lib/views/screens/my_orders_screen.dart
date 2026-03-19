import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../controllers/orders_controller.dart';
import '../../model/order_model.dart';
import '../../routes/AppRoutes.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrdersController controller = Get.find<OrdersController>();
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    // Check for success popup flag from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = Get.arguments;
      if (args is Map && args['showSuccessPopup'] == true && !_popupShown) {
        final orderType = args['orderType'] ?? 'Online';
        final paymentId = args['paymentId'];
        _showOrderSuccessPopup(context, orderType, paymentId);
        _popupShown = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).appBarTheme.titleTextStyle?.color,
              size: 20),
          onPressed: () => Get.offAllNamed(AppRoutes.mainLayout),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildOrderCard(context, controller.orders[index]);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.mainLayout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            child: Text(
              'Start Shopping',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            order.formattedOrderDate,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Order Type Badge
                          _buildOrderTypeBadge(context, order.orderType),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, order.status),
              ],
            ),
          ),

          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show first 2 items
                ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    )),

                // Show more items indicator
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '+${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                const SizedBox(height: 12),

                // Total and Delivery Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    if (order.isDelivered)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Delivered on',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.formattedDeliveredDate,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    // View Details Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showOrderDetails(context, order);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Download Receipt Button
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _generateAndDownloadReceipt(order),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: Text(
                          'Receipt',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a small badge showing the order type (COD or Online)
  Widget _buildOrderTypeBadge(BuildContext context, String orderType) {
    final bool isCod =
        orderType.toUpperCase() == 'COD' || orderType.toUpperCase() == 'CASH ON DELIVERY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCod
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCod ? Icons.money_rounded : Icons.account_balance_wallet_rounded,
            size: 12,
            color: isCod ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 4),
          Text(
            isCod ? 'COD' : 'Online',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isCod ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
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

  void _showOrderDetails(BuildContext context, OrderModel order) {
    final bool isCod =
        order.orderType.toUpperCase() == 'COD' || order.orderType.toUpperCase() == 'CASH ON DELIVERY';
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Order Details',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 20),

                _buildDetailRow(
                    context, 'Order Number', order.orderNumber),
                _buildDetailRow(
                    context, 'Order Date', order.formattedOrderDate),
                if (order.isDelivered)
                  _buildDetailRow(context, 'Delivered On',
                      order.formattedDeliveredDate),
                _buildDetailRow(
                    context, 'Status', _getStatusText(order.status)),
                _buildDetailRow(
                    context, 'Delivery Address', order.deliveryAddress),
                _buildDetailRow(context, 'Total Amount',
                    '₹${order.totalAmount.toStringAsFixed(0)}'),

                // Payment Method row
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Payment',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCod
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCod
                                        ? Icons.money_rounded
                                        : Icons.account_balance_wallet_rounded,
                                    size: 14,
                                    color: isCod
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCod
                                        ? 'Cash on Delivery'
                                        : 'Online Payment',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCod
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (order.paymentId != null && order.paymentId!.isNotEmpty)
                  _buildDetailRow(
                      context, 'Payment ID', order.paymentId!),

                const SizedBox(height: 20),

                Text(
                  'Items (${order.items.length})',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),

                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Download Receipt Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _generateAndDownloadReceipt(order),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'Download Receipt',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────
  //  ORDER SUCCESS POPUP
  // ────────────────────────────────────────────────────
  void _showOrderSuccessPopup(
      BuildContext context, String orderType, String? paymentId) {
    final bool isCod =
        orderType.toUpperCase() == 'COD' || orderType.toUpperCase() == 'CASH ON DELIVERY';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with colored ring
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Order Placed!',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                isCod
                    ? 'Your Cash on Delivery order has been confirmed. Pay when your order is delivered.'
                    : 'Your payment was successful and your order has been confirmed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              if (paymentId != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: Color(0xFF6366F1), size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'TXN: $paymentId',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Order type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCod
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCod
                          ? Icons.money_rounded
                          : Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: isCod
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCod ? 'Cash on Delivery' : 'Paid Online',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCod
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'VIEW MY ORDERS',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Get.back();
                  Get.offAllNamed(AppRoutes.mainLayout);
                },
                child: Text(
                  'Continue Shopping',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ────────────────────────────────────────────────────
  //  PDF RECEIPT GENERATION
  // ────────────────────────────────────────────────────
  Future<void> _generateAndDownloadReceipt(OrderModel order) async {
    final pdf = pw.Document();
    final bool isCod = order.orderType.toUpperCase() == 'COD' ||
        order.orderType.toUpperCase() == 'CASH ON DELIVERY';
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Kissan Fresh',
                          style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal)),
                      pw.SizedBox(height: 4),
                      pw.Text('Order Receipt',
                          style: pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: isCod ? PdfColors.green50 : PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      isCod ? 'CASH ON DELIVERY' : 'ONLINE PAYMENT',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: isCod ? PdfColors.green800 : PdfColors.indigo800,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Order Info
              _pdfInfoRow('Order Number', order.orderNumber),
              _pdfInfoRow('Order Date',
                  dateFormat.format(order.orderDate)),
              _pdfInfoRow('Status', order.statusText),
              if (order.paymentId != null && order.paymentId!.isNotEmpty)
                _pdfInfoRow('Payment ID', order.paymentId!),
              _pdfInfoRow('Payment Method',
                  isCod ? 'Cash on Delivery' : 'Online Payment'),
              _pdfInfoRow(
                  'Delivery Address', order.deliveryAddress),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Items header
              pw.Text('Items',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      _pdfTableCell('Item', isHeader: true),
                      _pdfTableCell('Qty', isHeader: true),
                      _pdfTableCell('Price', isHeader: true),
                      _pdfTableCell('Total', isHeader: true),
                    ],
                  ),
                  // Item rows
                  ...order.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _pdfTableCell(item.title),
                        _pdfTableCell('${item.quantity}'),
                        _pdfTableCell(
                            '₹${item.price.toStringAsFixed(0)}'),
                        _pdfTableCell(
                            '₹${(item.price * item.quantity).toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfTotalRow('Subtotal',
                        '₹${order.subtotal.toStringAsFixed(0)}'),
                    if (order.deliveryFee > 0)
                      _pdfTotalRow('Delivery Fee',
                          '₹${order.deliveryFee.toStringAsFixed(0)}'),
                    if (order.deliveryFee == 0)
                      _pdfTotalRow(
                          'Delivery Fee', 'FREE', isGreen: true),
                    if (order.discount > 0)
                      _pdfTotalRow('Discount',
                          '-₹${order.discount.toStringAsFixed(0)}',
                          isGreen: true),
                    if (order.couponDiscount > 0)
                      _pdfTotalRow('Coupon Discount',
                          '-₹${order.couponDiscount.toStringAsFixed(0)}',
                          isGreen: true),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Amount',
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Kissan Fresh!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print/share dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KissanFresh_${order.orderNumber}',
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfTotalRow(String label, String value,
      {bool isGreen = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: isGreen ? PdfColors.green : PdfColors.black)),
        ],
      ),
    );
  }
}