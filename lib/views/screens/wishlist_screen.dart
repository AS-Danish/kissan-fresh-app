import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/wishlist_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../model/product_card_model.dart';
import '../../routes/app_routes.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/floating_cart_snackbar.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered. It should be if accessed via product details.
    // If navigating directly, we might need to put it, but let's assume it's global or put it here.
    final WishlistController controller = Get.put(WishlistController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Your Wishlist',
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
        if (controller.wishlistItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your wishlist is empty',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore products and add them here',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.58,
          ),
          itemCount: controller.wishlistItems.length,
          itemBuilder: (context, index) {
            final product = controller.wishlistItems[index];

            // Get real-time data if available
            final realTimeData = controller.realTimeProductData[product.id];

            bool effectiveInStock = product.inStock;
            double effectivePrice = product.price;
            double? effectiveMrp = product.mrp;
            
            if (realTimeData != null) {
              effectiveInStock = realTimeData['inStock'] ?? true;
              if (realTimeData['price'] != null) {
                effectivePrice = (realTimeData['price'] as num).toDouble();
              }
              if (realTimeData['mrp'] != null) {
                effectiveMrp = (realTimeData['mrp'] as num).toDouble();
              }
            }

            // Create a wrapper product with functional callbacks and real-time data
            final functionalProduct = product.copyWith(
              inStock: effectiveInStock,
              price: effectivePrice,
              mrp: effectiveMrp,
              stockCount: effectiveInStock ? 99 : 0,
              onTap: () {
                Get.toNamed(
                  AppRoutes.productDetailsRoute,
                  arguments: product,
                );
              },
              onAddToCart: () {
                try {
                  final cartController = Get.find<CartController>();
                  bool added = cartController.addToCart(product, 1);
                  if (added) {
                    Get.snackbar(
                      'Added to Cart',
                      '${product.title} added to cart',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF10B981),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  }
                } catch (e) {
                  debugPrint("CartController not found: $e");
                }
              },
            );

            return ProductCardWidget(
              product: functionalProduct,
              showAddButton: true,
            );
          },
        );
      }),
      bottomNavigationBar: const FloatingCartSnackbar(bottomPadding: 16.0),
    );
  }
}
