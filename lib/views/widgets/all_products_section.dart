import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/products_controller.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

List<Widget> buildAllProductsSection(BuildContext context) {
  final controller = Get.find<ProductsController>();
  final homepageController = Get.find<HomepageController>();

  String title = "All Products";
  String category = 'All';
  if (homepageController.currentTab.value == 'Grocery') {
    if (homepageController.categories.isNotEmpty) {
      category = homepageController.categories[homepageController.selectedIndex.value].label;
      if (category != 'All') title = category;
    }
  } else {
    if (homepageController.homeFoodCategories.isNotEmpty) {
      category = homepageController.homeFoodCategories[homepageController.selectedHomeFoodIndex.value].label;
      if (category != 'All') title = category;
    }
  }

  List<Widget> slivers = [];

  // Section Header
  slivers.add(
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Fresh & Quality Products",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Get.toNamed(
                  AppRoutes.searchRoute,
                  arguments: {'category': category},
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                    size: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));

  if (controller.isLoadingProducts.value && controller.products.isEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  } else if (!controller.isLoadingProducts.value && controller.products.isEmpty) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "No products available.",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  } else {
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.52,
          ),
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            return ProductCardWidget(
              product: controller.products[index],
              showAddButton: true,
            );
          },
        ),
      ),
    );

    if (controller.isFetchingMore.value) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (controller.hasMoreProducts.value) {
      // Invisible padding at the bottom to give space before the next fetch is triggered
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 48)));
    }
  }

  return slivers;
}
