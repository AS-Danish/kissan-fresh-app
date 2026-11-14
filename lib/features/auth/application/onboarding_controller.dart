import 'package:kissanfresh/features/delivery/data/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/features/account/domain/user_model.dart';
import 'package:kissanfresh/features/delivery/domain/address_model.dart';
import 'package:kissanfresh/features/account/data/user_service.dart';
import 'package:kissanfresh/routes/app_routes.dart';

class OnboardingController extends FeatureController {
  final Ref ref;

  OnboardingController(this.ref);

  final UserService _userService = UserService();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  double? selectedLat;
  double? selectedLng;

  var isLoading = Observable(false);

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty ||
        address.isEmpty ||
        selectedLat == null ||
        selectedLng == null) {
      CustomSnackBar.show(
        'Error',
        'Name and Address (via map) are required',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      CustomSnackBar.show(
        'Error',
        'User not authenticated',
        snackPosition: SnackPosition.bottom,
      );
      return;
    }

    isLoading.value = true;
    try {
      final newAddress = AddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Home',
        mapAddress: address,
        latitude: selectedLat!,
        longitude: selectedLng!,
      );

      final userModel = UserModel(
        id: currentUser.uid,
        name: name,
        phoneNumber: currentUser.phoneNumber ?? '',
        email: email.isNotEmpty ? email : null,
        address: address,
        imageUrl: null,
        role: 'user',
        onboardingCompleted: true,
        savedAddresses: [newAddress],
        createdAt: DateTime.now(),
      );

      await _userService.createUser(userModel);

      // Sync address globally to LocationService for immediate use
      ref.read(locationServiceProvider).currentAddress.value = address;

      isLoading.value = false;

      AppNavigator.offAllNamed(AppRoutes.mainLayout);
      CustomSnackBar.show(
        'Welcome!',
        'Your profile has been set up successfully.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;
      CustomSnackBar.show(
        'Error',
        'Could not complete onboarding. Try again.',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}

final onboardingControllerProvider = Provider(
  (ref) => startController(ref, OnboardingController(ref)),
);
