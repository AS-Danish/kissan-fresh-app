import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/views/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Obx(() {
      if (authController.firebaseUser.value != null) {
        return child;
      } else {
        return LoginScreen();
      }
    });
  }
}
