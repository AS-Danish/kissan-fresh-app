import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../model/section_model.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/floating_cart_snackbar.dart';

class SectionProductsScreen extends StatelessWidget {
  final SectionModel section;

  const SectionProductsScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final HomepageController controller = Get.find<HomepageController>();
    
    // Fetch full products list when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchFullProductsForSection(section);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          section.name,
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final products = controller.sectionProducts[section.id] ?? [];

        if (controller.isLoadingSections.value && products.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "No products found in this section",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.58,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCardWidget(
              product: products[index],
              showAddButton: true,
            );
          },
        );
      }),
      bottomNavigationBar: const FloatingCartSnackbar(bottomPadding: 16.0),
    );
  }
}
