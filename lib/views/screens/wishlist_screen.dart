import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/wishlist_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../model/product_card_model.dart';
import '../../routes/app_routes.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/floating_cart_snackbar.dart';
import '../../controllers/bottom_bar_controller.dart';

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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (Get.isRegistered<BottomBarController>()) {
                      Get.find<BottomBarController>().changePage(0);
                      Get.until((route) => route.settings.name == AppRoutes.mainLayout || route.isFirst);
                    } else {
                      Get.offAllNamed(AppRoutes.mainLayout);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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

            ProductCardModel baseProduct = product;
            
            if (realTimeData != null) {
              final mapData = Map<String, dynamic>.from(realTimeData);
              mapData['id'] ??= product.id;
              baseProduct = ProductCardModel.fromJson(mapData);
            }

            // Create a wrapper product with functional callbacks and real-time data
            final functionalProduct = baseProduct.copyWith(
              onTap: () {
                Get.toNamed(
                  AppRoutes.productDetailsRoute,
                  arguments: baseProduct,
                );
              },
              onAddToCart: () {
                try {
                  final cartController = Get.find<CartController>();
                  bool added = cartController.addToCart(baseProduct, 1);
                  if (added) {
                    Get.snackbar(
                      'Added to Cart',
                      '${baseProduct.title} added to cart',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF14B8A6),
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
