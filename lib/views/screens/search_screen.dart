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
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 20,
                        color: Color(0xFF9AA7AC),
                      ),
                      onPressed: () {
                        searchTextController.clear();
                        controller.searchQuery.value = '';
                      },
                    )
                        : const SizedBox.shrink()),
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

              if (controller.searchQuery.value.isNotEmpty &&
                  products.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No products found',
                  message: 'Try searching with different keywords or browse categories',
                );
              }

              if (products.isEmpty) {
                return const EmptyStateWidget(
                  title: 'Start searching',
                  message: 'Search for your favorite products',
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
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
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
