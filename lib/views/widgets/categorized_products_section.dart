import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/categorized_products_controller.dart';
import 'product_card_widget.dart';

class CategorizedProductsSection extends StatelessWidget {
  CategorizedProductsSection({super.key});

  final CategorizedProductsController controller = Get.put(CategorizedProductsController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.categorizedProducts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF0d9488)),
          ),
        );
      }

      if (controller.categorizedProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.categorizedProducts.entries.map((entry) {
          final categoryName = entry.key;
          final products = entry.value;

          if (products.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "See all",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0d9488),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Horizontal Scroll
              SizedBox(
                height: 250, // Height for ProductCardWidget
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 160,
                      child: ProductCardWidget(product: products[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      );
    });
  }
}
