import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/location_service.dart';
import '../../../routes/app_routes.dart';

class CartSummaryWidget extends StatelessWidget {
  const CartSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController controller = Get.find<CartController>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coupon Section
              _buildCouponSection(context, controller),

              const SizedBox(height: 20),

              // Price Summary
              _buildPriceSummary(context, controller),

              const SizedBox(height: 20),

              // Checkout Button
              _buildCheckoutButton(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, CartController controller) {
    final TextEditingController couponTextController = TextEditingController();

    return Obx(() {
      final bool hasCoupon = controller.appliedCoupon.value.isNotEmpty;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasCoupon
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: hasCoupon
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coupon "${controller.appliedCoupon.value}" applied',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'You saved ₹${controller.discount.toStringAsFixed(0)}!',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.removeCoupon(),
                    child: Text(
                      'REMOVE',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(
                    Icons.confirmation_num_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: couponTextController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        controller.applyCoupon(couponTextController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: controller.isApplyingCoupon.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'APPLY',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildPriceSummary(BuildContext context, CartController controller) {
    return Obx(
      () => Column(
        children: [
          _buildPriceRow(
            context,
            controller,
            'Subtotal',
            '₹${controller.subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            context,
            controller,
            'Delivery Fee',
            '₹${controller.deliveryFee.toStringAsFixed(0)}',
            isDelivery: controller.deliveryFee == 0,
          ),
          if (controller.discount > 0) const SizedBox(height: 8),
          if (controller.discount > 0)
            _buildPriceRow(
              context,
              controller,
              controller.appliedCoupon.value.isNotEmpty
                  ? 'Coupon Discount (${controller.appliedCoupon.value})'
                  : 'Discount',
              '-₹${controller.discount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    CartController controller,
    String label,
    String amount, {
    bool isDelivery = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            letterSpacing: 0.1,
          ),
        ),
        Row(
          children: [
            if (isDelivery)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              amount,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDiscount
                    ? const Color(0xFF10B981)
                    : isDelivery
                    ? Colors.grey.shade400
                    : Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.2,
                decoration: isDelivery && controller.deliveryFee == 0
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartController controller) {
    return Obx(() {
      final outOfStockItems = controller.cartItems
          .where((item) => !item.inStock)
          .toList();
      final insufficientStockItems = controller.cartItems
          .where((item) => item.count > item.availableStock)
          .toList();
      final bool isCheckoutDisabled =
          outOfStockItems.isNotEmpty || insufficientStockItems.isNotEmpty;

      String errorMessage = 'FINAL TOTAL';
      if (outOfStockItems.isNotEmpty) {
        errorMessage = 'ITEMS OUT OF STOCK';
      } else if (insufficientStockItems.isNotEmpty) {
        errorMessage = 'INSUFFICIENT STOCK';
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isCheckoutDisabled
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: isCheckoutDisabled
              ? []
              : [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isCheckoutDisabled
                ? null
                : () {
                    // Check if user is logged in
                    if (AuthController.instance.firebaseUser.value == null) {
                      Get.toNamed(AppRoutes.loginScreen);
                      Get.snackbar(
                        'Login Required',
                        'Please login to proceed with checkout',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                      );
                      return;
                    }

                    // Show Order Summary
                    _showOrderSummaryPopup(context, controller);
                  },
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side - Final Total
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCheckoutDisabled ? errorMessage : 'FINAL TOTAL',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isCheckoutDisabled
                              ? 'CHECK ITEMS'
                              : '₹${controller.total.toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                            fontSize: isCheckoutDisabled ? 18 : 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Side - Proceed to Pay
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCheckoutDisabled ? 'DISABLED' : 'PROCEED',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCheckoutDisabled
                              ? Icons.lock_outline
                              : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showOrderSummaryPopup(BuildContext context, CartController controller) {
    Get.bottomSheet(
      Obx(
        () => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                'Order Summary',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please confirm your items and total price',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Delivery Address Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deliver to',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            Get.find<LocationService>().currentAddress.value ??
                                "No address selected",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Items List Summary
              Container(
                constraints: BoxConstraints(maxHeight: Get.height * 0.25),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.cartItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = controller.cartItems[index];
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
                                    '${item.count} x ₹${item.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (item.mrp != null && item.mrp! > item.price) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹${item.mrp!.toStringAsFixed(0)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade400,
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
                          '₹${(item.price * item.count).toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // Full Price Breakdown
              Column(
                children: [
                  _buildPriceRow(
                    context,
                    controller,
                    'Subtotal',
                    '₹${controller.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    context,
                    controller,
                    'Delivery Fee',
                    '₹${controller.deliveryFee.toStringAsFixed(0)}',
                    isDelivery: controller.deliveryFee == 0,
                  ),
                  if (controller.discount > 0) ...[
                    const SizedBox(height: 6),
                    _buildPriceRow(
                      context,
                      controller,
                      controller.appliedCoupon.value.isNotEmpty
                          ? 'Coupon Savings'
                          : 'Discount',
                      '-₹${controller.discount.toStringAsFixed(0)}',
                      isDiscount: true,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Final Total Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount Payable',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '₹${controller.total.toStringAsFixed(0)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close bottom sheet
                    Get.toNamed(AppRoutes.slotSelectionRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CONFIRM ORDER',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Wait, I want to add more',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
