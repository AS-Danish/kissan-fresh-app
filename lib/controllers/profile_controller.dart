import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // Observable variables
  var name = 'Abdul Salaam Danish'.obs;
  var email = 'asdanish123@gmail.com'.obs;
  var address = 'Azam Colony, Roshan Gate\nAurangabad, Maharashtra'.obs;
  var phoneNumber = '+91 98765 43210'.obs;
  
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
    // Initialize controllers with current values
    nameController = TextEditingController(text: name.value);
    emailController = TextEditingController(text: email.value);
    addressController = TextEditingController(text: address.value);
    phoneController = TextEditingController(text: phoneNumber.value);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void updateProfile() {
    // Validate inputs (basic)
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar(
        'Error', 
        'Name and Phone number are required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Update observable values
    name.value = nameController.text;
    // email.value = emailController.text; // Keeping email static for now
    address.value = addressController.text;
    phoneNumber.value = phoneController.text;

    // Show success message
    Get.snackbar(
      'Success',
      'Profile updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
    
    // Optionally navigate back
    // Get.back();
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
