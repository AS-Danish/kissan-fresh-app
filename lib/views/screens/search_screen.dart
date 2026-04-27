import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/product_search_controller.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/selectable_category_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/floating_cart_snackbar.dart';

class SearchScreen extends StatelessWidget {
  final ProductSearchController controller =
      Get.find<ProductSearchController>();
  late final TextEditingController searchTextController;

  SearchScreen({super.key}) {
    searchTextController = TextEditingController(
      text: controller.searchQuery.value,
    );

    // Listen to changes in the controller's search query to update the text field
    // (Crucial for voice search results to appear in the bar)
    ever(controller.searchQuery, (String query) {
      if (searchTextController.text != query) {
        searchTextController.text = query;
        // Move cursor to end
        searchTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: query.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Search Products',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchTextController,
                  autofocus: true,
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for products...',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.search,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: Obx(() {
                      if (controller.isListening.value) {
                        return IconButton(
                          icon: const Icon(
                            Icons.stop_circle,
                            size: 24,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            controller.stopListening();
                          },
                        );
                      } else if (controller.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: Color(0xFF9AA7AC),
                          ),
                          onPressed: () {
                            searchTextController.clear();
                            controller.searchQuery.value = '';
                          },
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(
                            Icons.mic,
                            size: 22,
                            color: Color(0xFF9AA7AC),
                          ),
                          onPressed: () {
                            controller.startListening();
                          },
                        );
                      }
                    }),
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Categories Section
            Obx(
              () => controller.searchQuery.value.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.recentSearches.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Recent Searches',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.recentSearches
                                  .map(
                                    (query) => InputChip(
                                      label: Text(
                                        query,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      deleteIconColor: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      onSelected: (_) {
                                        searchTextController.text = query;
                                        controller.searchQuery.value = query;
                                      },
                                      onDeleted: () {
                                        controller.removeRecentSearch(query);
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Categories',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final category = controller.categories[index];
                              return Obx(
                                () => SelectableCategoryCard(
                                  icon: category['icon'] as IconData,
                                  label: category['name'] as String,
                                  isSelected:
                                      controller.selectedCategory.value ==
                                      category['name'],
                                  iconColor: category['color'] as Color,
                                  onTap: () {
                                    if (controller.selectedCategory.value ==
                                        category['name']) {
                                      controller.selectedCategory.value = 'All';
                                    } else {
                                      controller.selectedCategory.value =
                                          category['name'] as String;
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Results Section
            Obx(() {
              final products = controller.filteredProducts;

              if (controller.isLoading.value && products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              }

              if (products.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No products found',
                  message:
                      'Try searching with different keywords or browse categories',
                  icon: Icons.search_off,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'Search Results'
                              : controller.selectedCategory.value == 'All'
                              ? 'All Products'
                              : controller.selectedCategory.value,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          '${products.length} item${products.length > 1 ? 's' : ''}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCardWidget(product: products[index]);
                      },
                    ),
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
                  else if (controller.hasMoreProducts.value &&
                      products.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => controller.fetchNextPage(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
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
                    ),
                  const SizedBox(height: 32),
                ],
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const FloatingCartSnackbar(bottomPadding: 16.0),
    );
  }
}
