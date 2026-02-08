import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OffersSection extends StatelessWidget {
  const OffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildOfferCard(
              icon: Icons.percent,
              iconBgColor: const Color(0xFFD5F5F2),
              iconColor: const Color(0xFF11968a),
              badge: 'EXCLUSIVE DEAL',
              badgeColor: const Color(0xFF11968a),
              title: 'FLAT ₹100 OFF',
              subtitle: 'On orders above ₹499',
            );
          } else if (index == 1) {
            return _buildOfferCard(
              icon: Icons.local_shipping_outlined,
              iconBgColor: const Color(0xFFFFF4E6),
              iconColor: const Color(0xFFFF9800),
              badge: 'FREE DELIVERY',
              badgeColor: const Color(0xFFFF9800),
              title: 'FREE Shipping',
              subtitle: 'On orders above ₹299',
            );
          } else {
            return _buildOfferCard(
              icon: Icons.card_giftcard,
              iconBgColor: const Color(0xFFFCE4EC),
              iconColor: const Color(0xFFE91E63),
              badge: 'NEW USER',
              badgeColor: const Color(0xFFE91E63),
              title: 'Get FLAT ₹50 OFF',
              subtitle: 'On first order above ₹199',
            );
          }
        },
      ),
    );
  }

  Widget _buildOfferCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badge,
                  style: GoogleFonts.montserrat(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
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
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}