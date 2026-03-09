import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/model/user_model.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';
import 'package:kissanfresh/services/location_service.dart';

class OnboardingController extends GetxController {
  final UserService _userService = UserService();
  
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  
  var isLoading = false.obs;

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

    if (name.isEmpty || address.isEmpty) {
      Get.snackbar(
        'Error',
        'Name and Address are required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'User not authenticated', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final userModel = UserModel(
        id: currentUser.uid,
        name: name,
        phoneNumber: currentUser.phoneNumber ?? '',
        email: email.isNotEmpty ? email : null,
        address: address,
        imageUrl: null, 
        role: 'user',
        onboardingCompleted: true,
        createdAt: DateTime.now(),
      );

      await _userService.createUser(userModel);
      
      // Sync address globally to LocationService for immediate use
      Get.find<LocationService>().currentAddress.value = address;

      isLoading.value = false;
      
      Get.offAllNamed(AppRoutes.mainLayout);
      Get.snackbar(
        'Welcome!',
        'Your profile has been set up successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not complete onboarding. Try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
