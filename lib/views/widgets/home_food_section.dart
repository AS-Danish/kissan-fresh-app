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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Special",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1f2937),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "View All",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0d9488),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Today's special item - Clickable
              GestureDetector(
                onTap: () {
                   // Navigate to the first item (Spicy Paneer Thali) as the special
                   if(controller.homeFoodProducts.isNotEmpty) {
                     controller.homeFoodProducts[0].onTap();
                   }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfff1f2),
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage("https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80"),
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
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Removed here
                        Text(
                          "Spicy Paneer Thali",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Includes 3 rotis, paneer gravy, rice, dal & salad",
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Explore Home Foods List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Explore Home Foods",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 16),
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
