import 'package:kissanfresh/features/delivery/data/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:hive/hive.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/features/auth/data/auth_service.dart';
import 'package:kissanfresh/features/account/data/user_service.dart';
import 'package:kissanfresh/features/account/data/notification_service.dart';
import 'package:kissanfresh/core/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends FeatureController {
  final Ref ref;

  AuthController(this.ref);

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  late Observable<User?> firebaseUser;
  StreamSubscription<User?>? _authSubscription;

  // Observables for UI
  var verificationId = Observable('');
  var isLoading = Observable(false);

  // Resend OTP variables
  var resendTimer = Observable(0);
  Timer? _countdownTimer;

  // Controllers
  final phoneController = TextEditingController();
  final otpController = TextEditingController(); // For OTP Screen if needed

  @override
  void onInit() {
    super.onInit();
    firebaseUser = Observable<User?>(_authService.currentUser);
    _authSubscription = _authService.authStateChanges.listen(
      (user) => firebaseUser.value = user,
    );
    observeField(firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    // This logic can be used to redirect, but since we have a hybrid approach
    // where home is always visible, we might not want to force redirect on init for everyone
    // unless they are in a protected route.
    // However, if the user IS logged in, we MUST verify onboarding status.
    if (user != null) {
      debugPrint("User is logged in: ${user.phoneNumber}");

      // Ensure FCM token is saved now that the user session is restored
      await NotificationService().saveTokenToFirestore();

      // Fetch user data from firestore to check onboarding
      final userModel = await _userService.getUser(user.uid);

      if (userModel == null || !userModel.onboardingCompleted) {
        // Profile is incomplete! Force them to onboarding screen
        debugPrint(
          "User onboarding is incomplete. Forcing redirect to onboarding.",
        );
        AppNavigator.offAllNamed(AppRoutes.onboardingRoute);
      } else {
        // User is fully onboarded.
        // If we are on login screen, or onboarding screen by mistake, go home
        if (AppNavigator.currentRoute == AppRoutes.loginScreen ||
            AppNavigator.currentRoute == AppRoutes.onboardingRoute) {
          AppNavigator.offAllNamed(AppRoutes.mainLayout);
        }
      }
    } else {
      debugPrint("User is logged out");
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _countdownTimer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }

  // Send OTP
  void sendOtp() async {
    if (isLoading.value) return;

    if (resendTimer.value > 0) {
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      CustomSnackBar.show(
        "Please Wait",
        "You can request another OTP in ${resendTimer.value} seconds.",
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!await NetworkService.isConnected()) {
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      NetworkService.showNoInternetSnackbar();
      return;
    }

    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      CustomSnackBar.show(
        "Error",
        "Please enter a valid 10-digit phone number",
        snackPosition: SnackPosition.bottom,
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
          if (AppNavigator.isDialogOpen) AppNavigator.back();
          _handleSuccess();
        },
        onVerificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          if (AppNavigator.isDialogOpen) AppNavigator.back();
          CustomSnackBar.show(
            "Verification Failed",
            e.message ?? "An error occurred",
            snackPosition: SnackPosition.bottom,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        },
        onCodeSent: (String vId, int? resendToken) {
          verificationId.value = vId;
          isLoading.value = false;
          if (AppNavigator.isDialogOpen) AppNavigator.back();
          _startResendTimer();
          // Navigate to OTP Screen if not already there
          if (AppNavigator.currentRoute != AppRoutes.otpVerificationRoute) {
            AppNavigator.toNamed(
              AppRoutes.otpVerificationRoute,
              arguments: phone,
            );
          }
        },
        onCodeAutoRetrievalTimeout: (String vId) {
          verificationId.value = vId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      CustomSnackBar.show(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    resendTimer.value = 60; // 60 seconds cooldown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void resendOtp(String phone) async {
    if (resendTimer.value > 0) return;
    phoneController.text =
        phone; // Ensure the phone controller has the correct context
    sendOtp();
  }

  // Verify OTP
  void verifyOtp(String smsCode) async {
    if (isLoading.value) return;

    if (!await NetworkService.isConnected()) {
      NetworkService.showNoInternetSnackbar();
      return;
    }

    if (smsCode.isEmpty || smsCode.length != 6) {
      CustomSnackBar.show(
        "Error",
        "Please enter a valid 6-digit OTP",
        snackPosition: SnackPosition.bottom,
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
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      _handleSuccess();
    } catch (e) {
      isLoading.value = false;
      if (AppNavigator.isDialogOpen) AppNavigator.back();
      CustomSnackBar.show(
        "Invalid OTP",
        "The entered OTP is incorrect. Please try again.",
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _handleSuccess() async {
    _countdownTimer?.cancel();
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userService.getUser(user.uid);
      final bool isFullyOnboarded =
          userModel != null && userModel.onboardingCompleted;

      if (isFullyOnboarded) {
        // Save FCM token after successful login
        await NotificationService().saveTokenToFirestore();

        // Populate global location logic via Firestore Profile
        if (userModel.address != null && userModel.address!.isNotEmpty) {
          ref.read(locationServiceProvider).currentAddress.value =
              userModel.address!;
        }

        AppNavigator.offAllNamed(
          AppRoutes.mainLayout,
        ); // Clear stack and go home
        CustomSnackBar.show(
          "Success",
          "Logged in successfully!",
          snackPosition: SnackPosition.bottom,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        AppNavigator.offAllNamed(AppRoutes.onboardingRoute);
        CustomSnackBar.show(
          "Welcome!",
          "Please complete your profile to continue.",
          snackPosition: SnackPosition.bottom,
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    } else {
      AppNavigator.offAllNamed(AppRoutes.mainLayout);
    }
  }

  void logout() {
    AppNavigator.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => AppNavigator.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AppNavigator.back(); // Close dialog immediately

                        // Execute slow operations asynchronously so the UI isn't blocked
                        Future.microtask(() async {
                          final box = Hive.box('user_settings');
                          await box.delete('current_address');
                          await box.delete('current_address_type');
                          await box.delete('current_flat_no');
                          await box.delete('current_landmark');
                          if (ref.exists(locationServiceProvider)) {
                            ref
                                    .read(locationServiceProvider)
                                    .currentAddressType
                                    .value =
                                'Current Location';
                            ref
                                .read(locationServiceProvider)
                                .fetchCurrentLocation();
                          }

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          await _authService.signOut();
                        });

                        CustomSnackBar.show(
                          "Success",
                          "Successfully Logged Out",
                          snackPosition: SnackPosition.bottom,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                        AppNavigator.offAllNamed(AppRoutes.mainLayout);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final authControllerProvider = Provider(
  (ref) => startController(ref, AuthController(ref)),
);
