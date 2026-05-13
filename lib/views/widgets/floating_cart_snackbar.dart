import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/cart_controller.dart';
import '../../routes/app_routes.dart';
import '../../controllers/bottom_bar_controller.dart';

class FloatingCartSnackbar extends StatelessWidget {
  final double bottomPadding;
  
  const FloatingCartSnackbar({super.key, this.bottomPadding = 16.0});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Obx(() {
      if (cartController.cartItems.isEmpty) return const SizedBox.shrink();

      final items = cartController.cartItems;
      final itemCount = cartController.totalItemCount;
      final discount = cartController.discount;

      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: bottomPadding,
        ),
        child: Material(
          color: Colors.transparent,
          elevation: 16,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Images Box
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < items.length && i < 2; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: items[i].image,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 36,
                                  height: 36,
                                  color: Colors.grey.shade200,
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        if (items.length > 2)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '+${items.length - 2}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Items Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$itemCount item${itemCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'You save ₹${discount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // View Cart Button
                  ElevatedButton(
                    onPressed: () {
                      if (Get.isRegistered<BottomBarController>()) {
                        Get.find<BottomBarController>().changePage(2); // Go to Cart Tab
                        Get.until((route) => route.settings.name == AppRoutes.mainLayout || route.isFirst);
                      } else {
                        Get.toNamed(AppRoutes.cartRoute);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'View Cart',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
