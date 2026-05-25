import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissanfresh/model/order_model.dart';
import 'package:kissanfresh/services/pdf_receipt_service.dart';
import 'package:kissanfresh/views/widgets/orders/order_badges.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailsSheet {
  static void show(BuildContext context, OrderModel order) {
    final bool isCod =
        order.orderType.toUpperCase() == 'COD' ||
        order.orderType.toUpperCase() == 'CASH ON DELIVERY';

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section: Order Information
                      _buildSectionHeader(context, 'Order Information'),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        'Order ID',
                        order.id,
                      ),
                      _buildDetailRow(
                        context,
                        'Internal Ref', // renamed from Order Number to keep it as secondary
                        order.orderNumber,
                      ),
                      _buildDetailRow(
                        context,
                        'Order Date',
                        order.formattedOrderDate,
                      ),
                      if (order.isDelivered)
                        _buildDetailRow(
                          context,
                          'Delivered On',
                          order.formattedDeliveredDate,
                        ),

                      const SizedBox(height: 20),

                      // Section: Delivery Details
                      _buildSectionHeader(context, 'Delivery Details'),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        'Address',
                        order.deliveryAddress,
                      ),
                      if (order.slot != null)
                        _buildDetailRow(
                          context,
                          'Time Slot',
                          '${DateFormat('hh:mm a').format(order.slot!.startTime)} - ${DateFormat('hh:mm a').format(order.slot!.endTime)}',
                        ),

                      const SizedBox(height: 20),

                      // Section: Rider Information
                      if (order.rider != null) ...[
                        _buildSectionHeader(context, 'Delivery Rider'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: order.rider!.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, url, error) => Icon(
                                          Icons.person,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.rider!.name,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.rider!.phone,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () async {
                                    final phone = order.rider!.phone;
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: phone,
                                    );
                                    try {
                                      if (await canLaunchUrl(launchUri)) {
                                        await launchUrl(launchUri);
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          'Could not launch dialer for $phone',
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(16),
                                          borderRadius: 12,
                                        );
                                      }
                                    } catch (e) {
                                      Get.snackbar(
                                        'Error',
                                        'An error occurred while launching the dialer',
                                        snackPosition: SnackPosition.BOTTOM,
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 12,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.call_rounded,
                                      size: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section: Payment Details
                      _buildSectionHeader(context, 'Payment Detail'),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Method',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCod
                                    ? const Color(
                                        0xFF14B8A6,
                                      ).withOpacity(0.1)
                                    : const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
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
                                        ? const Color(0xFF14B8A6)
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
                                          ? const Color(0xFF14B8A6)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.paymentId != null &&
                          order.paymentId!.isNotEmpty)
                        _buildDetailRow(
                          context,
                          'Transaction ID',
                          order.paymentId!,
                        ),

                      const SizedBox(height: 20),

                      // Section: Items
                      _buildSectionHeader(
                        context,
                        'Items (${order.items.length})',
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: item.image,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (
                                          context,
                                          url,
                                          error,
                                        ) => const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey,
                                        ),
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.quantity} x ₹${item.price.toStringAsFixed(0)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (item.mrp != null && item.mrp! > item.price) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '₹${item.mrp!.toStringAsFixed(0)}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: Summary
                      _buildSectionHeader(context, 'Order Summary'),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        context,
                        'Subtotal',
                        '₹${order.subtotal.toStringAsFixed(0)}',
                      ),
                      if (order.deliveryFee > 0)
                        _buildSummaryRow(
                          context,
                          'Delivery Fee',
                          '₹${order.deliveryFee.toStringAsFixed(0)}',
                        ),
                      if (order.deliveryFee == 0)
                        _buildSummaryRow(
                          context,
                          'Delivery Fee',
                          'FREE',
                          isGreen: true,
                        ),
                      if (order.discount > 0)
                        _buildSummaryRow(
                          context,
                          'Product Discount',
                          '-₹${order.discount.toStringAsFixed(0)}',
                          isGreen: true,
                        ),
                      if (order.couponDiscount > 0)
                        _buildSummaryRow(
                          context,
                          'Coupon Discount',
                          '-₹${order.couponDiscount.toStringAsFixed(0)}',
                          isGreen: true,
                        ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => PdfReceiptService.generateAndDownloadReceipt(order),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(
                      'Close Detail',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).primaryColor.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
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

  static Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isGreen = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: isGreen ? FontWeight.w700 : FontWeight.w600,
              color: isGreen
                  ? const Color(0xFF14B8A6)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
