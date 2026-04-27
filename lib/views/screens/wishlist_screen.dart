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
                    ).dividerColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
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
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: controller.wishlistItems.length,
          itemBuilder: (context, index) {
            final product = controller.wishlistItems[index];

            // Get real-time data if available
            final realTimeData = controller.realTimeProductData[product.id];

            // Primary logic: use real-time inStock boolean, if available.
            // User requested to ignore stockCount for wishlist availability.
            bool effectiveInStock = product.inStock;
            if (realTimeData != null) {
              effectiveInStock = realTimeData['inStock'] ?? true;
            }

            // Create a wrapper product with functional callbacks and real-time stock
            final functionalProduct = ProductCardModel(
              id: product.id,
              image: product.image,
              images: product.images,
              title: product.title,
              description: product.description,
              price: product.price,
              unit: product.unit,
              category: product.category,
              inStock: effectiveInStock,
              // We set stockCount to 1 if inStock is true to satisfy ProductCardWidget's UI logic
              // which checks both inStock AND stockCount > 0.
              stockCount: effectiveInStock ? 1 : 0,
              onTap: () {
                Get.toNamed(
                  AppRoutes.productDetailsRoute,
                  arguments: product, // Pass the original product or update it too if needed
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
