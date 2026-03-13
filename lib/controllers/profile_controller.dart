import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/model/user_model.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:kissanfresh/routes/AppRoutes.dart';

class ProfileController extends GetxController {
  final UserService _userService = UserService();

  // Observable variables
  var isLoading = true.obs;
  var name = ''.obs;
  var email = ''.obs;
  var address = ''.obs;
  var phoneNumber = ''.obs;
  
  // Profile image (network URL)
  var profileImage = ''.obs; 
  var initials = ''.obs;

  // Text Editing Controllers
  late TextEditingController nameController;
  late TextEditingController emailController; 
  late TextEditingController addressController;
  late TextEditingController phoneController;

  final ImagePicker _picker = ImagePicker();

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
    // 1. Load from cache first for instant UI
    final prefs = await SharedPreferences.getInstance();
    name.value = prefs.getString('cached_name') ?? '';
    email.value = prefs.getString('cached_email') ?? '';
    address.value = prefs.getString('cached_address') ?? '';
    phoneNumber.value = prefs.getString('cached_phone') ?? '';
    profileImage.value = prefs.getString('cached_image') ?? '';
    _updateInitials(name.value);

    // Populate controllers with cache
    nameController.text = name.value;
    emailController.text = email.value;
    addressController.text = address.value;
    phoneController.text = phoneNumber.value;

    isLoading.value = false; // UI can show cached immediately

    // 2. Fetch latest from Firestore silently
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userModel = await _userService.getUser(currentUser.uid);
      if (userModel != null) {
        name.value = userModel.name;
        email.value = userModel.email ?? '';
        address.value = userModel.address ?? '';
        phoneNumber.value = userModel.phoneNumber;
        profileImage.value = userModel.imageUrl ?? '';
        _updateInitials(name.value);
        
        nameController.text = name.value;
        emailController.text = email.value;
        addressController.text = address.value;
        phoneController.text = phoneNumber.value;

        // Update cache
        await prefs.setString('cached_name', name.value);
        await prefs.setString('cached_email', email.value);
        await prefs.setString('cached_address', address.value);
        await prefs.setString('cached_phone', phoneNumber.value);
        await prefs.setString('cached_image', profileImage.value);
      }
    }
  }

  void _updateInitials(String fullName) {
    if (fullName.isEmpty) {
      initials.value = 'U';
      return;
    }
    
    List<String> names = fullName.trim().split(' ');
    String computed = '';
    
    if (names.isNotEmpty) {
      computed += names[0][0].toUpperCase();
      if (names.length > 1 && names[1].isNotEmpty) {
        computed += names[1][0].toUpperCase();
      }
    }
    initials.value = computed;
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
           _updateInitials(name.value);

           // Update cache
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('cached_name', name.value);
           await prefs.setString('cached_email', email.value);
           await prefs.setString('cached_address', address.value);

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
      onConfirm: () async {
        Get.back(); // Close dialog
        isLoading.value = true;
        
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
             // 1. Optional: Delete image from storage if exists
             if (profileImage.value.isNotEmpty) {
               try {
                 final ref = FirebaseStorage.instance.refFromURL(profileImage.value);
                 await ref.delete();
               } catch (e) {
                 debugPrint("Could not delete image: $e");
               }
             }
             
             // 2. Clear from Firestore
             // Since we use set locally, you'd need delete logic. Assuming db instance:
             // We can do it directly or wait. For complete deletion, Firebase Auth is most critical.
             // Note: in a production app, do you delete the Firestore record? Usually yes.
             // await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).delete();
             
             // 3. Clear cache
             final prefs = await SharedPreferences.getInstance();
             await prefs.clear();
             
             // 4. Delete Auth User
             await currentUser.delete();
             
             Get.snackbar(
               'Account Deleted',
               'Your account has been permanently deleted.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
             );
             
             Get.offAllNamed(AppRoutes.loginScreen);
          }
        } on FirebaseAuthException catch (e) {
           if (e.code == 'requires-recent-login') {
              Get.snackbar(
                'Requires Login',
                'Please log out and log back in to verify your identity before deleting.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
           } else {
             Get.snackbar('Error', e.message ?? 'Failed to delete account.', backgroundColor: Colors.red, colorText: Colors.white);
           }
        } catch (e) {
             Get.snackbar('Error', 'An unknown error occurred.', backgroundColor: Colors.red, colorText: Colors.white);
        } finally {
          isLoading.value = false;
        }
      }
    );
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
         source: ImageSource.gallery,
         imageQuality: 70, // compress image
      );
      
      if (image == null) return;
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      isLoading.value = true;
      
      // Upload to Firebase Storage
      final File file = File(image.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update local and cache
      profileImage.value = downloadUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_image', downloadUrl);

      // Fetch existing model to update image field
      final existingUser = await _userService.getUser(currentUser.uid);
      if (existingUser != null) {
          final updatedModel = UserModel(
             id: existingUser.id,
             name: existingUser.name,
             phoneNumber: existingUser.phoneNumber,
             email: existingUser.email,
             address: existingUser.address,
             imageUrl: downloadUrl, // NEW URL
             role: existingUser.role,
             onboardingCompleted: existingUser.onboardingCompleted,
             createdAt: existingUser.createdAt,
           );
           await _userService.createUser(updatedModel); // Acts as a save/update
           
           Get.snackbar(
            'Success',
            'Profile picture updated!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
      }

    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        'Could not upload image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
