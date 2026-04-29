import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kissanfresh/model/order_model.dart';
import 'package:kissanfresh/services/pdf_receipt_service.dart';
import 'package:kissanfresh/views/widgets/orders/order_badges.dart';
import 'package:kissanfresh/views/widgets/orders/order_details_sheet.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
                        'ID: ${order.id}',
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
                          OrderTypeBadge(orderType: order.orderType),
                        ],
                      ),
                    ],
                  ),
                ),
                OrderStatusBadge(status: order.status),
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
                ...order.items
                    .take(2)
                    .map(
                      (item) => Padding(
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
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs.${item.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (item.mrp != null && item.mrp! > item.price)
                                  Text(
                                    'Rs.${item.mrp!.toStringAsFixed(0)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

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
                Container(height: 1, color: Colors.grey.shade200),

                const SizedBox(height: 12),

                // Delivery Slot Info
                if (order.slot != null && !order.isDelivered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Arriving between ${DateFormat('hh:mm a').format(order.slot!.startTime)} and ${DateFormat('hh:mm a').format(order.slot!.endTime)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                          'Rs.${order.totalAmount.toStringAsFixed(0)}',
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
                          OrderDetailsSheet.show(context, order);
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
                        onPressed: () => PdfReceiptService.generateAndDownloadReceipt(order),
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
}
