import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import '../../controllers/products_controller.dart';
import '../components/all_products_section.dart';
import '../components/bestseller_section.dart';
import '../components/categories_section.dart';
import '../components/offer_section.dart';
import '../components/welcome_section.dart';
import '../widgets/home_header.dart';

class ImprovedHomeScreen extends StatelessWidget {
  ImprovedHomeScreen({super.key}) {
    Get.put(ProductsController());
  }

  final HomepageController controller = Get.put(
    HomepageController(),
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(),
            const SizedBox(height: 24),
            CategoriesSection(controller: controller),
            const SizedBox(height: 32),
            const WelcomeSection(),
            const SizedBox(height: 24),
            const OffersSection(),
            const SizedBox(height: 32),
            BestsellersSection(),
            const SizedBox(height: 32),
            AllProductsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}