import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/categorized_products_controller.dart';
import '../../model/product_card_model.dart';
import '../../routes/app_routes.dart';
import 'product_card_widget.dart';

List<Widget> buildCategorizedProductsSection(BuildContext context) {
  final CategorizedProductsController controller =
      Get.find<CategorizedProductsController>();

  if (controller.isLoading.value && controller.categorizedProducts.isEmpty) {
    return [
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
    ];
  }

  if (controller.categorizedProducts.isEmpty) {
    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  final entries = controller.currentCategories
      .map(
        (category) => MapEntry(
          category,
          controller.categorizedProducts[category] ?? const [],
        ),
      )
      .where((entry) => entry.value.isNotEmpty)
      .toList(growable: false);

  return [
    SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _CategoryProductRow(
          key: ValueKey(entry.key),
          categoryName: entry.key,
          products: entry.value,
        );
      },
    ),
  ];
}

class _CategoryProductRow extends StatelessWidget {
  const _CategoryProductRow({
    super.key,
    required this.categoryName,
    required this.products,
  });

  final String categoryName;
  final List<ProductCardModel> products;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Explore our $categoryName collection',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(
                    AppRoutes.searchRoute,
                    arguments: {'category': categoryName},
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.1),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'See all',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: ListView.separated(
              key: PageStorageKey('category-$categoryName'),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  key: ValueKey(product.id ?? '${categoryName}_$index'),
                  width: 115,
                  child: ProductCardWidget(product: product),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
