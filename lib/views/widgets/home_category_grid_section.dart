import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/categorized_products_controller.dart';
import '../../controllers/homepage_controller.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

class HomeCategoryGridSection extends StatelessWidget {
  final String categoryName;
  final String title;

  HomeCategoryGridSection({
    super.key,
    required this.categoryName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final CategorizedProductsController controller = Get.find<
      CategorizedProductsController
    >();
    return Obx(() {
      final products = controller.categorizedProducts[categoryName] ?? [];
      
      if (products.isEmpty) {
        return const SizedBox.shrink();
      }

      // Limit to 6 products for the grid
      final displayProducts = products.take(6).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Product Grid (3 columns, 2 rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62, // Adjusted for ProductCardWidget
              ),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                return ProductCardWidget(
                  product: displayProducts[index],
                  showAddButton: true,
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // See All Products Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to search screen with selected category
                  Get.toNamed(
                    AppRoutes.searchRoute,
                    arguments: {'category': categoryName},
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "See all products",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    });
  }
}
