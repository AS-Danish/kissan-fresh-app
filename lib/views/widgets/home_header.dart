import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../routes/AppRoutes.dart';
import '../screens/search_screen.dart';
import 'home_tab_toggle.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
                        onTap: () async {
                          final result = await Get.toNamed(AppRoutes.addressSelectionRoute);
                          if (result != null && result is Map<String, dynamic>) {
                            Get.find<HomepageController>().updateAddress(result['address'] ?? '');
                          }
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
                                child: Obx(() => Text(
                                  Get.find<HomepageController>().currentAddress.value ?? 'Fetching location...',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )),
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
                    onPressed: () {
                      Get.toNamed(AppRoutes.profileRoute);
                    },
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
              child: GestureDetector(
                onTap: () {
                   Get.toNamed(AppRoutes.searchRoute);
                },
                behavior: HitTestBehavior.opaque,
                child: IgnorePointer(
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
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          icon: const Icon(Icons.mic, size: 22, color: Color(0xFF9AA7AC)),
                          onPressed: () {
                            Get.toNamed(AppRoutes.searchRoute, arguments: {'startSpeech': true});
                          },
                        ),
                      ),
                    ),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Toggle Switch
            const HomeTabToggle(),
          ],
        ),
      ),
    );
  }
}