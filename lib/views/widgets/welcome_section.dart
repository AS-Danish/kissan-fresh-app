import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/theme_controller.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        // Force rebuild on theme change
        Get.find<ThemeController>().isDarkMode.value;
        final isGrocery =
            Get.find<HomepageController>().currentTab.value == 'Grocery';
        return Column(
          children: [
            Text(
              isGrocery ? "WELCOME" : "HOME FOOD",
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGrocery
                  ? "Order now and enjoy great offers"
                  : "Authentic homemade meals",
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      }),
    );
  }
}
