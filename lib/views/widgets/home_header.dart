import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';
import 'home_tab_toggle.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomepageController>();
    return Obx(() {
      final imageUrl = controller.headerImageUrl.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl) as ImageProvider
                : const AssetImage('assets/images/header_bg.png'),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black38,
              BlendMode.darken,
            ),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.9),
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
                          final result = await Get.toNamed(
                            AppRoutes.addressSelectionRoute,
                          );
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            Get.find<HomepageController>().updateAddress(
                              result['address'] ?? '',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          child: Obx(() {
                            final locationService = Get.find<LocationService>();
                            final isDenied =
                                locationService.locationPermissionDenied.value;

                            if (isDenied) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Location Disabled',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.redAccent,
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
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    Get.find<HomepageController>()
                                            .currentAddress
                                            .value ??
                                        'Fetching location...',
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
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GetBuilder<ProfileController>(
                  init: ProfileController(),
                  builder: (profileController) {
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.profileRoute);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: profileController.profileImage.value.isEmpty
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Obx(
                          () => profileController.profileImage.value.isEmpty
                              ? Center(
                                  child: Text(
                                    profileController.initials.value.isNotEmpty
                                        ? profileController.initials.value
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: profileController.profileImage.value,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.search,
                          size: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          icon: const Icon(
                            Icons.mic,
                            size: 22,
                            color: Color(0xFF9AA7AC),
                          ),
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.searchRoute,
                              arguments: {'startSpeech': true},
                            );
                          },
                        ),
                      ),
                    ),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
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
    });
  }
}
