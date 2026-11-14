import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';
import 'package:kissanfresh/core/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FieldBuilder(() {
        // Force rebuild on theme change
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(themeControllerProvider).isDarkMode.value;
        final isGrocery =
            ProviderScope.containerOf(
              context,
              listen: false,
            ).read(homepageControllerProvider).currentTab.value ==
            'Grocery';
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
