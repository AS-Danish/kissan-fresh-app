import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/features/auth/application/auth_controller.dart';
import 'package:kissanfresh/features/auth/presentation/screens/login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthController authController = ref.watch(authControllerProvider);

    return FieldBuilder(() {
      if (authController.firebaseUser.value != null) {
        return child;
      } else {
        return LoginScreen();
      }
    });
  }
}
