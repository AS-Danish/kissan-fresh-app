import 'package:kissanfresh/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/controllers/profile_controller.dart';
import 'package:kissanfresh/model/address_model.dart';
import 'package:kissanfresh/model/user_model.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAddressesScreen extends StatelessWidget {
  const ManageAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Addresses',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        final profileController = Get.find<ProfileController>();
        final addresses =
            profileController.currentUser.value?.savedAddresses ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved addresses',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, profileController);
            },
          );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.addressSelectionRoute);
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add New',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    AddressModel address,
    ProfileController controller,
  ) {
    IconData icon;
    if (address.type.toLowerCase() == 'home') {
      icon = Icons.home_rounded;
    } else if (address.type.toLowerCase() == 'office') {
      icon = Icons.work_rounded;
    } else {
      icon = Icons.location_on_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.type,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address.fullAddress,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteAddress(context, address, controller),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete Address',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    AddressModel addressToDelete,
    ProfileController profileController,
  ) async {
    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Delete Address',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: GoogleFonts.montserrat(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && profileController.currentUser.value != null) {
        final userModel = profileController.currentUser.value!;

        final updatedAddresses = List<AddressModel>.from(
          userModel.savedAddresses,
        );
        updatedAddresses.removeWhere((a) => a.id == addressToDelete.id);

        final updatedUser = UserModel(
          id: userModel.id,
          name: userModel.name,
          phoneNumber: userModel.phoneNumber,
          email: userModel.email,
          address: userModel.address,
          imageUrl: userModel.imageUrl,
          role: userModel.role,
          onboardingCompleted: userModel.onboardingCompleted,
          savedAddresses: updatedAddresses,
          createdAt: userModel.createdAt,
        );

        final userService = UserService();
        await userService.updateUser(updatedUser);

        // Also update local profile state manually to avoid race conditions
        profileController.currentUser.value = updatedUser;
        profileController.update();

        CustomSnackBar.show(
          'Success',
          'Address deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }
}
