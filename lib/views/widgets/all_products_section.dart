import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/homepage_controller.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

class AllProductsSection extends StatelessWidget {
  AllProductsSection({super.key});

  final ProductsController controller = Get.find<ProductsController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final homepageController = Get.find<HomepageController>();
                    String title = "All Products";
                    if (homepageController.currentTab.value == 'Grocery') {
                      final lbl = homepageController
                          .categories[homepageController.selectedIndex.value]
                          .label;
                      if (lbl != 'All') title = lbl;
                    } else {
                      final lbl = homepageController
                          .homeFoodCategories[homepageController
                              .selectedHomeFoodIndex
                              .value]
                          .label;
                      if (lbl != 'All') title = lbl;
                    }
                    return Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    );
                  }),
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
                  final homepageController = Get.find<HomepageController>();
                  String category = 'All';
                  if (homepageController.currentTab.value == 'Grocery') {
                    category = homepageController
                        .categories[homepageController.selectedIndex.value]
                        .label;
                  } else {
                    category = homepageController
                        .homeFoodCategories[homepageController
                            .selectedHomeFoodIndex
                            .value]
                        .label;
                  }
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
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Products Grid - 2 columns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() {
            if (controller.isLoadingProducts.value &&
                controller.products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }

            if (!controller.isLoadingProducts.value &&
                controller.products.isEmpty) {
              return Padding(
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
              );
            }

            return Column(
              children: [
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    return ProductCardWidget(
                      product: controller.products[index],
                      showAddButton: false,
                    );
                  },
                ),
                if (controller.isFetchingMore.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                else if (controller.hasMoreProducts.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: OutlinedButton(
                      onPressed: () => controller.fetchNextPage(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Load More",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
