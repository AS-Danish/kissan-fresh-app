import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';
import 'package:kissanfresh/services/auth_service.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:kissanfresh/services/location_service.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  late Rx<User?> firebaseUser;
  
  // Observables for UI
  var verificationId = ''.obs;
  var isLoading = false.obs;
  
  // Controllers
  final phoneController = TextEditingController();
  final otpController = TextEditingController(); // For OTP Screen if needed

  @override
  void onInit() {
    super.onInit();
    firebaseUser = Rx<User?>(_authService.currentUser);
    firebaseUser.bindStream(_authService.authStateChanges);
    ever(firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    // This logic can be used to redirect, but since we have a hybrid approach 
    // where home is always visible, we might not want to force redirect on init for everyone
    // unless they are in a protected route.
    // However, if the user IS logged in, we MUST verify onboarding status.
    if (user != null) {
      debugPrint("User is logged in: ${user.phoneNumber}");
      
      // Fetch user data from firestore to check onboarding
      final userModel = await _userService.getUser(user.uid);
      
      if (userModel == null || !userModel.onboardingCompleted) {
         // Profile is incomplete! Force them to onboarding screen
         debugPrint("User onboarding is incomplete. Forcing redirect to onboarding.");
         Get.offAllNamed(AppRoutes.onboardingRoute);
      } else {
         // User is fully onboarded.
         // If we are on login screen, or onboarding screen by mistake, go home
         if (Get.currentRoute == AppRoutes.loginScreen || 
             Get.currentRoute == AppRoutes.onboardingRoute) {
            Get.offAllNamed(AppRoutes.mainLayout);
         }
      }
    } else {
       debugPrint("User is logged out");
    }
  }

  // Send OTP
  void sendOtp() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      Get.snackbar(
        "Error",
        "Please enter a valid 10-digit phone number",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android devices
          await _authService.signInWithCredential(credential);
          isLoading.value = false;
          _handleSuccess();
        },
        onVerificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar(
            "Verification Failed",
            e.message ?? "An error occurred",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        },
        onCodeSent: (String vId, int? resendToken) {
          verificationId.value = vId;
          isLoading.value = false;
          // Navigate to OTP Screen
          Get.toNamed(AppRoutes.otpVerificationRoute, arguments: phone);
        },
        onCodeAutoRetrievalTimeout: (String vId) {
          verificationId.value = vId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // Verify OTP
  void verifyOtp(String smsCode) async {
    if (smsCode.isEmpty || smsCode.length != 6) {
       Get.snackbar(
        "Error",
        "Please enter a valid 6-digit OTP",
        snackPosition: SnackPosition.BOTTOM,
         backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _authService.signInWithSmsCode(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      isLoading.value = false;
      _handleSuccess();
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Invalid OTP",
        "The entered OTP is incorrect. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
         backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _handleSuccess() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userService.getUser(user.uid);
      final bool isFullyOnboarded = userModel != null && userModel.onboardingCompleted;
      
      if (isFullyOnboarded) {
        
        // Populate global location logic via Firestore Profile
        if (userModel?.address != null && userModel!.address!.isNotEmpty) {
           Get.find<LocationService>().currentAddress.value = userModel.address;
        }

        Get.offAllNamed(AppRoutes.mainLayout); // Clear stack and go home
        Get.snackbar(
          "Success",
          "Logged in successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.offAllNamed(AppRoutes.onboardingRoute);
        Get.snackbar(
          "Welcome!",
          "Please complete your profile to continue.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    } else {
      Get.offAllNamed(AppRoutes.mainLayout);
    }
  }

  void logout() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.mainLayout);
  }
}
