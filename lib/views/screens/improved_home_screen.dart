import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/homepage_controller.dart';
import '../widgets/all_products_section.dart';
import '../widgets/bestseller_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/home_food_section.dart';
import '../widgets/offer_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/home_header.dart';
import '../widgets/categorized_products_section.dart';

class ImprovedHomeScreen extends StatelessWidget {
  const ImprovedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomepageController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 24),
            Obx(() {
              if (controller.currentTab.value == 'Grocery') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoriesSection(
                      categories: controller.categories,
                      selectedIndex: controller.selectedIndex.value,
                      onCategorySelected: controller.selectCategory,
                    ),
                    const SizedBox(height: 32),
                    const WelcomeSection(),
                    const SizedBox(height: 24),
                    const OffersSection(),
                    const SizedBox(height: 32),
                    BestsellersSection(),
                    const SizedBox(height: 32),
                    AllProductsSection(),
                    const SizedBox(height: 32),
                    CategorizedProductsSection(),
                    const SizedBox(height: 32),
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