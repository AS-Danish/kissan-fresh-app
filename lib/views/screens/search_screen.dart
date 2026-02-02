import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/product_search_controller.dart';
import '../widgets/product_card_widget.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  final ProductSearchController controller = Get.put(ProductSearchController());
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
                      return Obx(() => _buildCategoryCard(
                        category: category,
                        isSelected: controller.selectedCategory.value ==
                            category['name'],
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
                return _buildEmptyState();
              }

              if (products.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0FDFA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off,
                            size: 60,
                            color: Color(0xFF0d9488),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start searching',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for your favorite products',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildCategoryCard({
    required Map<String, dynamic> category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0d9488).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 28,
                color: isSelected ? Colors.white : category['color'] as Color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: Color(0xFF0d9488),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No products found',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Try searching with different keywords or browse categories',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}