import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/model/user_model.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:kissanfresh/services/location_service.dart';

class ProfileController extends GetxController {
  final UserService _userService = UserService();

  // Observable variables
  var isLoading = true.obs;
  var name = ''.obs;
  var email = ''.obs;
  var address = ''.obs;
  var phoneNumber = ''.obs;
  
  // Profile image (using asset placeholder or network image for now)
  // In a real app, this would use ImagePicker
  var profileImage = ''.obs; 

  // Text Editing Controllers
  late TextEditingController nameController;
  late TextEditingController emailController; // Usually read-only or requires verify
  late TextEditingController addressController;
  late TextEditingController phoneController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController(); 
    addressController = TextEditingController();
    phoneController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userModel = await _userService.getUser(currentUser.uid);
      if (userModel != null) {
        name.value = userModel.name;
        email.value = userModel.email ?? '';
        address.value = userModel.address ?? '';
        phoneNumber.value = userModel.phoneNumber;
        
        nameController.text = name.value;
        emailController.text = email.value;
        addressController.text = address.value;
        phoneController.text = phoneNumber.value;
      }
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void updateProfile() async {
    // Validate inputs (basic)
    if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
      Get.snackbar(
        'Error', 
        'Name and Address are required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Fetch existing model to preserve roles/creation date, or update directly
        final existingUser = await _userService.getUser(currentUser.uid);
        if (existingUser != null) {
           final updatedModel = UserModel(
             id: existingUser.id,
             name: nameController.text.trim(),
             phoneNumber: existingUser.phoneNumber, // Don't alter raw phone
             email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
             address: addressController.text.trim(),
             imageUrl: existingUser.imageUrl,
             role: existingUser.role,
             onboardingCompleted: existingUser.onboardingCompleted,
             createdAt: existingUser.createdAt,
           );

           await _userService.createUser(updatedModel);

           // Sync the observable values locally for the UI
           name.value = updatedModel.name;
           email.value = updatedModel.email ?? '';
           address.value = updatedModel.address ?? '';

           // Update global location service with newest address
           Get.find<LocationService>().currentAddress.value = updatedModel.address;

           Get.snackbar(
            'Success',
            'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }
      }
    } catch (e) {
       Get.snackbar(
        'Error',
        'Could not update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
       isLoading.value = false;
    }
  }
  
  void deleteAccount() {
    Get.defaultDialog(
      title: "Delete Account",
      middleText: "Are you sure you want to delete your account? This action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        // Perform delete logic
        Get.back(); // Close dialog
        // Navigate to Login or show success
        Get.snackbar(
          'Account Deleted',
          'Your account has been permanently deleted.',
           snackPosition: SnackPosition.BOTTOM,
        );
        // Simulate logout/delete
        // Get.offAllNamed(AppRoutes.loginScreen);
      }
    );
  }

  void pickImage() {
    // Placeholder for Image Picker
    Get.snackbar(
      'Change Photo',
      'Image picker feature coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
