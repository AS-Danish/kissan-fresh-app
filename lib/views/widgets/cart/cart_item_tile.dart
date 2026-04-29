import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';

import '../../../model/coupon_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartController controller;

  const CartItemTile({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final coupon = controller.activeCouponModel.value;
      bool isCouponApplied = false;
      if (coupon != null) {
        if (coupon.applyTo == 'all') {
          isCouponApplied = true;
        } else if (coupon.applicableCategory != null &&
            item.category == coupon.applicableCategory) {
          isCouponApplied = true;
        } else if (coupon.applicableProduct != null &&
            item.id == coupon.applicableProduct) {
          isCouponApplied = true;
        }
      }

      return Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
              Icons.delete_outline, color: Colors.white, size: 28),
        ),
        onDismissed: (direction) {
          controller.removeItem(item.id);
          Get.snackbar(
            'Removed',
            '${item.name} removed from cart',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .colorScheme
                .surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isCouponApplied
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : Theme
                  .of(context)
                  .dividerColor
                  .withOpacity(0.5),
              width: isCouponApplied ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: item.inStock ? 1.0 : 0.5,
                    child: CachedNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                            ),
                          ),
                      errorWidget: (context, url, error) =>
                          Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onSurface,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            controller.removeItem(item.id);
                            Get.snackbar(
                              'Removed',
                              '${item.name} removed from cart',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black87,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.quantity,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!item.inStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                        if (isCouponApplied) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_num, size: 10,
                                    color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'Coupon Applied',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isCouponApplied) ...[
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${_calculateDiscountedItemPrice(item, coupon!).toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981), // Success Green
                              letterSpacing: 0.3,
                            ),
                          ),
                        ] else ...[
                          if (item.mrp != null && item.mrp! > item.price)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(
                                '₹${item.mrp!.toStringAsFixed(0)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Quantity Controls
                        _buildQuantityControls(context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  double _calculateDiscountedItemPrice(CartItem item, CouponModel coupon) {
    if (coupon.discountType == 'percentage') {
      return item.price * (1 - (coupon.discountValue / 100));
    } else {
      // Proportional distribution for flat discounts
      double applicableSubtotal = controller.cartItems
          .where((i) => i.category == coupon.applicableCategory || coupon.applyTo == 'all')
          .fold(0.0, (sum, i) => sum + (i.price * i.count));
          
      if (applicableSubtotal == 0) return item.price;
      
      double itemTotal = item.price * item.count;
      double proportionalDiscount = (itemTotal / applicableSubtotal) * coupon.discountValue;
      return (itemTotal - proportionalDiscount) / item.count;
    }
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            context: context,
            icon: Icons.remove,
            onPressed: item.count > 1
                ? () => controller.decrementItem(item.id)
                : null,
            isDisabled: item.count <= 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.count}',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          _buildQuantityButton(
            context: context,
            icon: Icons.add,
            onPressed: () => controller.incrementItem(item.id),
            isDisabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDisabled,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
