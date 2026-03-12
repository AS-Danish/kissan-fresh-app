import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/product_search_controller.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/selectable_category_card.dart';
import '../widgets/empty_state_widget.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  final ProductSearchController controller = Get.find<ProductSearchController>();
  final TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FFFE),
        elevation: 0,
        title: Text(
          'Search Products',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF2D3748),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                      color: const Color(0xFF8E9AA0),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.search,
                        size: 24,
                        color: Color(0xFF11968a),
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
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Categories Section
            Obx(() => controller.searchQuery.value.isEmpty
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
                        color: Colors.black87,
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
                      children: controller.recentSearches.map((query) => InputChip(
                        label: Text(
                          query,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        backgroundColor: Colors.white,
                        deleteIconColor: const Color(0xFF8E9AA0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onSelected: (_) {
                          searchTextController.text = query;
                          controller.searchQuery.value = query;
                        },
                        onDeleted: () {
                          controller.removeRecentSearch(query);
                        },
                      )).toList(),
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
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = controller.categories[index];
                      return Obx(() => SelectableCategoryCard(
                        icon: category['icon'] as IconData,
                        label: category['name'] as String,
                        isSelected: controller.selectedCategory.value == category['name'],
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
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            )
                : const SizedBox.shrink()),

            // Results Section
            Obx(() {
              final products = controller.filteredProducts;

              if (controller.isLoading.value && products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0d9488),
                    ),
                  ),
                );
              }

              if (products.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No products found',
                  message: 'Try searching with different keywords or browse categories',
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
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          '${products.length} item${products.length > 1 ? 's' : ''}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0d9488),
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCardWidget(product: products[index]);
                      },
                    ),
                  ),
                  if (controller.isFetchingMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0d9488),
                        ),
                      ),
                    )
                  else if (controller.hasMoreProducts.value && products.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => controller.fetchNextPage(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0d9488),
                            side: const BorderSide(color: Color(0xFF0d9488)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
    );
  }
}
