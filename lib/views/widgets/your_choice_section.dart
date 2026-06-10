import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/user_activity_controller.dart';
import '../../model/product_card_model.dart';
import 'product_card_widget.dart';

class YourChoiceSection extends StatelessWidget {
  YourChoiceSection({super.key});

  final UserActivityController controller = Get.find<UserActivityController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.personalizedProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pick up Where you Left Off",
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Based on your recent activity",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal Scroll List
          SizedBox(
            height: 200, // Matching standard horizontal product card height
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: controller.personalizedProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = controller.personalizedProducts[index];
                
                // Get real-time data if available
                final realTimeData = controller.realTimeProductData[product.id];
                
                ProductCardModel displayProduct = product;
                if (realTimeData != null) {
                  final mapData = Map<String, dynamic>.from(realTimeData);
                  mapData['id'] ??= product.id;
                  displayProduct = ProductCardModel.fromJson(
                    mapData,
                    onTap: product.onTap,
                    onAddToCart: product.onAddToCart,
                  );
                }

                return SizedBox(
                  width: 130, // Optimized width for horizontal scroll
                  child: ProductCardWidget(
                    product: displayProduct,
                    showAddButton: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32), // Bottom spacing for the next section
        ],
      );
    });
  }
}
