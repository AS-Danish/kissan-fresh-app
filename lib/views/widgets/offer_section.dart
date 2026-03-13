import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/theme_controller.dart';

class OffersSection extends StatelessWidget {
  const OffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: Obx(() {
        // Force rebuild on theme change for card/badge colors
        Get.find<ThemeController>().isDarkMode.value;
        final isGrocery =
            Get.find<HomepageController>().currentTab.value == 'Grocery';
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildOfferCard(
                context: context,
                icon: Icons.percent,
                iconBgColor: Theme.of(context).primaryColor.withOpacity(0.1),
                iconColor: Theme.of(context).primaryColor,
                badge: 'EXCLUSIVE DEAL',
                badgeColor: Theme.of(context).primaryColor,
                title: isGrocery ? 'FLAT ₹100 OFF' : 'FLAT ₹50 OFF',
                subtitle: isGrocery
                    ? 'On orders above ₹499'
                    : 'On orders above ₹299',
              );
            } else if (index == 1) {
              return _buildOfferCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                iconBgColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                iconColor: Theme.of(context).colorScheme.secondary,
                badge: 'FREE DELIVERY',
                badgeColor: Theme.of(context).colorScheme.secondary,
                title: 'FREE Shipping',
                subtitle: isGrocery
                    ? 'On orders above ₹299'
                    : 'On orders above ₹199',
              );
            } else {
              return _buildOfferCard(
                context: context,
                icon: Icons.card_giftcard,
                iconBgColor: Theme.of(context).primaryColor.withOpacity(0.2),
                iconColor: Theme.of(context).primaryColor,
                badge: 'NEW USER',
                badgeColor: Theme.of(context).primaryColor,
                title: isGrocery ? 'Get FLAT ₹50 OFF' : 'FREE DESSERT',
                subtitle: isGrocery
                    ? 'On first order above ₹199'
                    : 'On first order above ₹249',
              );
            }
          },
        );
      }),
    );
  }

  Widget _buildOfferCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.light 
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badge,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Arrow icon
          Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).dividerColor),
        ],
      ),
    );
  }
}