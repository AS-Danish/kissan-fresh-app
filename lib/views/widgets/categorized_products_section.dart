import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/categorized_products_controller.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

class CategorizedProductsSection extends StatelessWidget {
  CategorizedProductsSection({super.key});

  final CategorizedProductsController controller = Get.find<
    CategorizedProductsController
  >();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value &&
          controller.categorizedProducts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      }

      if (controller.categorizedProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.categorizedProducts.entries.map((entry) {
          final categoryName = entry.key;
          final products = entry.value;

          if (products.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Explore our $categoryName collection",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.searchRoute,
                          arguments: {'category': categoryName},
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "See all",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Horizontal Scroll
              SizedBox(
                height: 200, // Height for ProductCardWidget in 3-column layout
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 115,
                      child: ProductCardWidget(
                        product: products[index].copyWith(
                          stockCount: 99,
                          inStock: true,
                        ),
                        showAddButton: false,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      );
    });
  }
}
