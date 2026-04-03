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
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildOfferCard(
                context: context,
                icon: Icons.percent,
                iconBgColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                iconColor: Theme.of(context).primaryColor,
                badge: 'EXCLUSIVE DEAL',
                badgeColor: Theme.of(context).primaryColor,
                title: isGrocery ? 'FLAT ₹100 OFF' : 'FLAT ₹50 OFF',
                subtitle: isGrocery
                    ? 'On orders above ₹499'
                    : 'On orders above ₹299',
                onTap: () => _showCouponDetails(
                  context,
                  title: isGrocery ? 'FLAT ₹100 OFF' : 'FLAT ₹50 OFF',
                  badge: 'EXCLUSIVE DEAL',
                  code: isGrocery ? 'KISSAN100' : 'FOOD50',
                  description: isGrocery
                      ? 'Get a flat ₹100 discount on your grocery order when you spend ₹499 or more.'
                      : 'Get a flat ₹50 discount on your food order when you spend ₹299 or more.',
                  howToApply: [
                    'Add products to your cart.',
                    'Go to the checkout page.',
                    'Tap on "Apply Coupon".',
                    'Select or enter ${isGrocery ? 'KISSAN100' : 'FOOD50'}.',
                  ],
                  limits: [
                    'Minimum order value: ${isGrocery ? '₹499' : '₹299'}.',
                    'Valid once per user.',
                    'Maximum discount: ${isGrocery ? '₹100' : '₹50'}.',
                  ],
                  criteria: 'Applicable on all items except dairy products.',
                ),
              );
            } else if (index == 1) {
              return _buildOfferCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                iconBgColor: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.2),
                iconColor: Theme.of(context).colorScheme.secondary,
                badge: 'FREE DELIVERY',
                badgeColor: Theme.of(context).colorScheme.secondary,
                title: 'FREE Shipping',
                subtitle: isGrocery
                    ? 'On orders above ₹299'
                    : 'On orders above ₹199',
                onTap: () => _showCouponDetails(
                  context,
                  title: 'FREE Shipping',
                  badge: 'FREE DELIVERY',
                  code: 'FREESHIP',
                  description: 'Enjoy free delivery on your orders. No delivery fees applied!',
                  howToApply: [
                    'Add items to your cart.',
                    'The free shipping will be automatically applied at checkout if criteria is met.',
                  ],
                  limits: [
                    'Minimum order value: ${isGrocery ? '₹299' : '₹199'}.',
                    'Valid for all users.',
                    'Applicable within 10km radius.',
                  ],
                  criteria: 'Available for both Grocery and Home Food orders.',
                ),
              );
            } else {
              return _buildOfferCard(
                context: context,
                icon: Icons.card_giftcard,
                iconBgColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                iconColor: Theme.of(context).primaryColor,
                badge: 'NEW USER',
                badgeColor: Theme.of(context).primaryColor,
                title: isGrocery ? 'Get FLAT ₹50 OFF' : 'FREE DESSERT',
                subtitle: isGrocery
                    ? 'On first order above ₹199'
                    : 'On first order above ₹249',
                onTap: () => _showCouponDetails(
                  context,
                  title: isGrocery ? 'FLAT ₹50 OFF' : 'FREE DESSERT',
                  badge: 'NEW USER OFFER',
                  code: 'WELCOME',
                  description: isGrocery
                      ? 'Welcome to Kissanfresh! Get flat ₹50 off on your first grocery shopping.'
                      : 'Treat yourself! Get a free dessert on your first home food order.',
                  howToApply: [
                    'Create a new account.',
                    'Place your first order.',
                    'Use code WELCOME at checkout.',
                  ],
                  limits: [
                    'Minimum order value: ${isGrocery ? '₹199' : '₹249'}.',
                    'Valid for first order only.',
                  ],
                  criteria: 'Valid for new registered users only.',
                ),
              );
            }
          },
        );
      }),
    );
  }

  void _showCouponDetails(
    BuildContext context, {
    required String title,
    required String badge,
    required String code,
    required String description,
    required List<String> howToApply,
    required List<String> limits,
    required String criteria,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Coupon Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COUPON CODE',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          code,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Copy logic could go here
                        Get.back();
                        Get.snackbar(
                          "Copied!",
                          "Coupon code $code copied to clipboard",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Theme.of(context).primaryColor,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      child: Text(
                        'COPY',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // How to Apply
              _buildSectionTitle(context, 'How to Apply'),
              ...howToApply.map((step) => _buildBulletPoint(context, step)),
              const SizedBox(height: 24),

              // Limit & Criteria
              _buildSectionTitle(context, 'Limit & Criteria'),
              ...limits.map((limit) => _buildBulletPoint(context, limit)),
              _buildBulletPoint(context, criteria),

              const SizedBox(height: 32),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Order Now to Apply",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).dividerColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
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
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey.shade600,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}
