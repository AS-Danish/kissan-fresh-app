import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppFeedbackType { success, error, warning, info }

class CustomSnackBar {
  static void success(String title, String message) =>
      show(title, message, feedbackType: AppFeedbackType.success);

  static void error(String title, String message) =>
      show(title, message, feedbackType: AppFeedbackType.error);

  static void warning(String title, String message) =>
      show(title, message, feedbackType: AppFeedbackType.warning);

  static void info(String title, String message) =>
      show(title, message, feedbackType: AppFeedbackType.info);

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
    AppFeedbackType? feedbackType,
  }) {
    // One concise message at a time prevents stale cart/network feedback from
    // stacking over the checkout controls.
    Get.closeAllSnackbars();

    final normalizedTitle = title.toLowerCase();
    final bool isErrorColor =
        backgroundColor == Colors.red ||
        backgroundColor == Colors.redAccent ||
        backgroundColor == Colors.red.shade800;
    final bool isWarningColor =
        backgroundColor == Colors.orange ||
        backgroundColor == Colors.orangeAccent ||
        backgroundColor == Colors.orange.shade800;
    final type =
        feedbackType ??
        (isErrorColor ||
                normalizedTitle.contains('error') ||
                normalizedTitle.contains('failed') ||
                normalizedTitle.contains('invalid')
            ? AppFeedbackType.error
            : isWarningColor || normalizedTitle.contains('warning')
            ? AppFeedbackType.warning
            : AppFeedbackType.success);
    final theme = Get.context == null
        ? ThemeData.light()
        : Theme.of(Get.context!);
    final scheme = theme.colorScheme;
    final accentColor = switch (type) {
      AppFeedbackType.success => scheme.tertiary,
      AppFeedbackType.error => scheme.error,
      AppFeedbackType.warning => const Color(0xFFF59E0B),
      AppFeedbackType.info => scheme.primary,
    };
    final feedbackIcon = switch (type) {
      AppFeedbackType.success => Icons.check_circle_rounded,
      AppFeedbackType.error => Icons.error_rounded,
      AppFeedbackType.warning => Icons.warning_amber_rounded,
      AppFeedbackType.info => Icons.info_rounded,
    };
    final foreground = scheme.onSurface;

    Get.rawSnackbar(
      titleText:
          titleText ??
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
      messageText:
          messageText ??
          Text(
            message,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.72),
              fontWeight: FontWeight.w400,
              fontSize: 13,
              height: 1.25,
            ),
          ),
      backgroundColor: scheme.surface,
      snackPosition: snackPosition ?? SnackPosition.BOTTOM,
      borderRadius: borderRadius ?? 16,
      margin: margin ?? const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      icon: icon ?? Icon(feedbackIcon, color: accentColor, size: 24),
      leftBarIndicatorColor: leftBarIndicatorColor ?? accentColor,
      borderColor: borderColor ?? scheme.outline.withValues(alpha: 0.18),
      borderWidth: borderWidth ?? 1,
      boxShadows:
          boxShadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
      shouldIconPulse: shouldIconPulse ?? false,
      duration: duration ?? const Duration(milliseconds: 2000),
      animationDuration: animationDuration ?? const Duration(milliseconds: 300),
      isDismissible: isDismissible ?? true,
      dismissDirection: dismissDirection ?? DismissDirection.horizontal,
      forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeInCirc,
      snackStyle: snackStyle ?? SnackStyle.FLOATING,
      mainButton: mainButton,
      onTap: onTap,
      showProgressIndicator: showProgressIndicator ?? false,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      maxWidth: maxWidth,
      barBlur: barBlur ?? 0,
      overlayBlur: overlayBlur ?? 0,
      overlayColor: overlayColor ?? Colors.transparent,
      snackbarStatus: snackbarStatus,
      userInputForm: userInputForm,
    );
  }
}
