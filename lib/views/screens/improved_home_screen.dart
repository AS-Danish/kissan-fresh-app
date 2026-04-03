import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/all_products_section.dart';
import '../widgets/bestseller_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/home_food_section.dart';
import '../widgets/offer_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/home_header.dart';
import '../widgets/categorized_products_section.dart';
import '../widgets/home_category_grid_section.dart';

class ImprovedHomeScreen extends StatelessWidget {
  const ImprovedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomepageController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeHeader(),
            const SizedBox(height: 24),
            Obx(() {
              // Ensure real-time theme updates
              Get.find<ThemeController>().isDarkMode.value;
              if (controller.currentTab.value == 'Grocery') {
                final isAll =
                    controller
                        .categories[controller.selectedIndex.value]
                        .label ==
                    'All';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoriesSection(
                      categories: controller.categories,
                      selectedIndex: controller.selectedIndex.value,
                      onCategorySelected: controller.selectCategory,
                    ),
                    const SizedBox(height: 32),
                    if (isAll) ...[
                      WelcomeSection(),
                      const SizedBox(height: 24),
                      OffersSection(),
                      const SizedBox(height: 32),
                      BestsellersSection(),
                      const SizedBox(height: 32),
                      HomeCategoryGridSection(
                        categoryName: 'Vegetables',
                        title: 'Daily Vegetables',
                      ),
                      HomeCategoryGridSection(
                        categoryName: 'Chicken',
                        title: 'Fresh Chicken',
                      ),
                      HomeCategoryGridSection(
                        categoryName: 'Meat',
                        title: 'Fresh Meat',
                      ),
                      HomeCategoryGridSection(
                        categoryName: 'Groceries',
                        title: 'Daily Groceries',
                      ),
                    ],
                    AllProductsSection(),
                    const SizedBox(height: 32),
                    if (isAll) ...[
                      CategorizedProductsSection(),
                      const SizedBox(height: 32),
                    ],
                  ],
                );
              } else {
                return Column(
                  children: [
                    const HomeFoodSection(),
                    const SizedBox(height: 32),
                    CategorizedProductsSection(),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
