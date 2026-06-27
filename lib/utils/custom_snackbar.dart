import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackBar {
  static void show(
    String title,
    String message, {
    Color? colorText,
    Duration? duration,
    SnackPosition? snackPosition,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    bool? isDismissible,
    bool? showProgressIndicator,
    DismissDirection? dismissDirection,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    double? barBlur,
    double? overlayBlur,
    SnackbarStatusCallback? snackbarStatus,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    // Close existing snackbars instantly to prevent queuing (Blinkit/Zepto style)
    Get.closeAllSnackbars();

    // Determine type based on provided background color
    bool isError =
        backgroundColor == Colors.red ||
        backgroundColor == Colors.redAccent ||
        backgroundColor == Colors.red.shade800;
    bool isWarning =
        backgroundColor == Colors.orange ||
        backgroundColor == Colors.orangeAccent ||
        backgroundColor == Colors.orange.shade800;

    // Clean, elegant colors
    Color finalBgColor = isError
        ? const Color(0xFFE53935) // Elegant Red
        : isWarning
        ? const Color(0xFFF57C00) // Elegant Orange
        : const Color(0xFF43A047); // Elegant Green

    Get.rawSnackbar(
      titleText:
          titleText ??
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
      messageText:
          messageText ??
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
          ),
      backgroundColor: finalBgColor,
      snackPosition: snackPosition ?? SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: margin ?? const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      icon:
          icon ??
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
      shouldIconPulse: shouldIconPulse ?? false,
      duration: duration ?? const Duration(milliseconds: 2000),
      animationDuration: animationDuration ?? const Duration(milliseconds: 300),
      isDismissible: isDismissible ?? true,
      dismissDirection: dismissDirection ?? DismissDirection.horizontal,
      forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeInCirc,
      snackStyle: SnackStyle.FLOATING,
    );
  }
}
