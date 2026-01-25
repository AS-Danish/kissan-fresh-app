import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryItemModel {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  CategoryItemModel({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class HomeScreenController extends GetxController {
  RxInt selectedIndex = 0.obs;

  final categories = [
    CategoryItemModel(
      label: "All",
      icon: FontAwesomeIcons.tableCells,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Winter",
      icon: FontAwesomeIcons.snowflake,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Electronics",
      icon: FontAwesomeIcons.desktop,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Beauty",
      icon: FontAwesomeIcons.spa,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Groceries",
      icon: FontAwesomeIcons.basketShopping,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fashion",
      icon: FontAwesomeIcons.shirt,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Footwear",
      icon: FontAwesomeIcons.shoePrints,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Home",
      icon: FontAwesomeIcons.couch,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Kitchen",
      icon: FontAwesomeIcons.utensils,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fitness",
      icon: FontAwesomeIcons.dumbbell,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Books",
      icon: FontAwesomeIcons.book,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Toys",
      icon: FontAwesomeIcons.puzzlePiece,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gaming",
      icon: FontAwesomeIcons.gamepad,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Music",
      icon: FontAwesomeIcons.music,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Travel",
      icon: FontAwesomeIcons.suitcaseRolling,
      onTap: () {},
    ),
    CategoryItemModel(label: "Pets", icon: FontAwesomeIcons.paw, onTap: () {}),
    CategoryItemModel(
      label: "Pharmacy",
      icon: FontAwesomeIcons.pills,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gifts",
      icon: FontAwesomeIcons.gift,
      onTap: () {},
    ),
  ];

  void selectCategory(int index) {
    selectedIndex.value = index;
  }
}

class ImprovedHomeScreen extends StatelessWidget {
  ImprovedHomeScreen({super.key});

  final HomeScreenController controller = Get.put(
    HomeScreenController(),
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            const SizedBox(height: 24),

            // Categories Section
            SizedBox(
              height: 110,
              child: Obx(() {
                final selected = controller.selectedIndex.value;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = controller.categories[index];
                    final bool isSelected = selected == index;

                    return GestureDetector(
                      onTap: () => controller.selectCategory(index),
                      child: buildCategoryCard(item, isSelected),
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 32),

            // Welcome Section - CENTERED
            Center(
              child: Column(
                children: [
                  Text(
                    "WELCOME",
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0d9488),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Order now and enjoy great offers",
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Offers Section - HORIZONTALLY SCROLLABLE
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return buildOfferCard(
                      icon: Icons.percent,
                      iconBgColor: const Color(0xFFD5F5F2),
                      iconColor: const Color(0xFF11968a),
                      badge: 'EXCLUSIVE DEAL',
                      badgeColor: const Color(0xFF11968a),
                      title: 'FLAT ₹100 OFF',
                      subtitle: 'On orders above ₹499',
                    );
                  } else if (index == 1) {
                    return buildOfferCard(
                      icon: Icons.local_shipping_outlined,
                      iconBgColor: const Color(0xFFFFF4E6),
                      iconColor: const Color(0xFFFF9800),
                      badge: 'FREE DELIVERY',
                      badgeColor: const Color(0xFFFF9800),
                      title: 'FREE Shipping',
                      subtitle: 'On orders above ₹299',
                    );
                  } else {
                    return buildOfferCard(
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
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget buildOfferCard({
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

  Widget buildCategoryCard(CategoryItemModel item, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0d9488) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0d9488).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: FaIcon(
              item.icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 68,
          child: Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0d9488)
                  : Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0d9488).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DELIVERING IN",
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: const Color(0xFFc6f8ee),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "12 mins",
                        style: GoogleFonts.montserrat(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          debugPrint("Changing Location");
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.locationDot,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "Azam Colony, Roshan Gate",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.user,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search "fresh organic avocados"',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF8E9AA0),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.search,
                      size: 24,
                      color: Color(0xFF11968a),
                    ),
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.mic, size: 22, color: Color(0xFF9AA7AC)),
                  ),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
