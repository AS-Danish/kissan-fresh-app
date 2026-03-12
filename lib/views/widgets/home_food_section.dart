import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../views/widgets/product_card_widget.dart';
import 'all_products_section.dart';
import 'categories_section.dart';

class HomeFoodSection extends StatelessWidget {
  const HomeFoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomepageController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories
        Obx(() => CategoriesSection(
          categories: controller.homeFoodCategories,
          selectedIndex: controller.selectedHomeFoodIndex.value,
          onCategorySelected: controller.selectHomeFoodCategory,
        )),
        const SizedBox(height: 32),

        // Today's Special
        Obx(() {
          final isAll = controller.homeFoodCategories[controller.selectedHomeFoodIndex.value].label == 'All';
          if (!isAll) return const SizedBox.shrink();

          if (controller.isLoadingSpecials.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.todaysSpecials.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Today's Special",
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1f2937),
                      ),
                    ),
                  ),
                  // Loop through specials
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.todaysSpecials.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final special = controller.todaysSpecials[index];
                        return GestureDetector(
                          onTap: special.onTap,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFfff1f2),
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(special.image),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.3, 0.7, 1.0],
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                    Colors.black.withOpacity(0.9),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    special.title,
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ]
          );
        }),

        // Explore Home Foods List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid of products
              AllProductsSection(),
            ],
          ),
        ),
        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }
}
