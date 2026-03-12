import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  // The priority can be specified if you have multiple middlewares
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // If the user already has a valid Firebase Session
    if (AuthController.instance.firebaseUser.value != null) {
      // Prevent them from going explicitly back to the login or OTP screen
      if (route == AppRoutes.loginScreen || route == AppRoutes.otpVerificationRoute) {
        // Reroute them silently back to the Home Layout
        return const RouteSettings(name: AppRoutes.mainLayout);
      }
    }
    // Otherwise, let them proceed normally
    return null;
  }
}

class RequireAuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (AuthController.instance.firebaseUser.value == null) {
      return const RouteSettings(name: AppRoutes.loginScreen);
    }
    return null;
  }
}
