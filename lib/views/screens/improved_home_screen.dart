import 'package:flutter/material.dart';
import '../widgets/all_products_section.dart';
import '../widgets/bestseller_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/offer_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/home_header.dart';

class ImprovedHomeScreen extends StatelessWidget {
  const ImprovedHomeScreen({super.key});

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
            CategoriesSection(),
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