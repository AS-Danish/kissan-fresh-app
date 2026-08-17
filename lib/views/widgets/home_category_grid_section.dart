import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/categorized_products_controller.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

List<Widget> buildHomeCategoryGridSection(BuildContext context, String categoryName, String title) {
  final CategorizedProductsController controller = Get.find<CategorizedProductsController>();
  final products = controller.categorizedProducts[categoryName] ?? [];

  if (products.isEmpty) {
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  final displayProducts = products.take(6).toList();

  return [
    SliverToBoxAdapter(
      child: Padding(
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
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 16)),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.52,
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
    const SliverToBoxAdapter(child: SizedBox(height: 20)),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Get.toNamed(
                AppRoutes.searchRoute,
                arguments: {'category': categoryName},
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 32)),
  ];
}
