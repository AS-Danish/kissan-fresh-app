import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/controllers/profile_controller.dart';
import 'package:kissanfresh/model/address_model.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressBottomSheet extends StatelessWidget {
  const AddressBottomSheet({super.key});

  static void show(BuildContext context) {
    Get.bottomSheet(
      const AddressBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a location',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Current Location Button
                  Obx(() {
                    final locService = Get.find<LocationService>();
                    final isSelected =
                        locService.currentAddressType.value ==
                        'Current Location';
                    return _buildActionTile(
                      context,
                      icon: Icons.my_location_rounded,
                      title: 'Use current location',
                      subtitle: 'Using GPS',
                      color: Theme.of(context).primaryColor,
                      isSelected: isSelected,
                      onTap: () async {
                        Get.back();
                        await locService.fetchCurrentLocation();
                      },
                    );
                  }),
                  const SizedBox(height: 16),

                  // Add New Address Button
                  _buildActionTile(
                    context,
                    icon: Icons.add_location_alt_rounded,
                    title: 'Add new address',
                    subtitle: 'Choose on map',
                    color: const Color(0xFF6366F1),
                    onTap: () async {
                      Get.back();
                      Get.toNamed(AppRoutes.addressSelectionRoute);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Saved Addresses Section
                  GetBuilder<ProfileController>(
                    init: Get.isRegistered<ProfileController>() ? null : ProfileController(),
                    builder: (profileController) {
                      final addresses =
                          profileController.currentUser.value?.savedAddresses ??
                          [];
                      if (addresses.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAVED ADDRESSES',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...addresses
                              .map(
                                (address) =>
                                    _buildSavedAddressTile(context, address),
                              )
                              .toList(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color)
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressTile(BuildContext context, AddressModel address) {
    IconData icon;
    if (address.type.toLowerCase() == 'home') {
      icon = Icons.home_rounded;
    } else if (address.type.toLowerCase() == 'office') {
      icon = Icons.work_rounded;
    } else {
      icon = Icons.location_on_rounded;
    }

    return Obx(() {
      final locService = Get.find<LocationService>();
      final isSelected =
          locService.currentAddressType.value == address.type &&
          locService.currentAddress.value == address.fullAddress;

      return InkWell(
        onTap: () async {
          Get.back(); // Close sheet
          final box = Hive.box('user_settings');
          await box.put('current_address', address.fullAddress);
          await box.put('current_address_type', address.type);
          await box.put('current_flat_no', address.flatNo ?? '');
          await box.put('current_landmark', address.landmark ?? '');
          await box.put('last_known_lat', address.latitude);
          await box.put('last_known_lng', address.longitude);

          if (Get.isRegistered<LocationService>()) {
            locService.currentAddressType.value = address.type;
            locService.currentAddress.value = address.fullAddress;
            if (address.latitude != null && address.longitude != null) {
              locService.currentLocation.value = LatLng(
                address.latitude!,
                address.longitude!,
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black87, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.type,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      );
    });
  }
}
