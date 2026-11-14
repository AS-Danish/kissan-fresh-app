import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kissanfresh/core/navigation.dart';

enum SnackPosition { top, bottom }

enum AppFeedbackType { success, error, warning, info }

class CustomSnackBar {
  static OverlayEntry? _entry;
  static Timer? _timer;
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
    VoidCallback? onTap,
    bool? isDismissible,
    AppFeedbackType? feedbackType,
  }) {
    final overlay = AppNavigator.key.currentState?.overlay;
    if (overlay == null) return;
    _entry?.remove();
    _timer?.cancel();
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
    final theme = AppNavigator.theme;
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

    void dismiss() {
      _entry?.remove();
      _entry = null;
      _timer?.cancel();
    }

    _entry = OverlayEntry(
      builder: (context) {
        final atTop = snackPosition == SnackPosition.top;
        final insets = margin ?? const EdgeInsets.all(16);
        return Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: atTop ? Alignment.topCenter : Alignment.bottomCenter,
              child: Padding(
                padding: insets,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth ?? 600),
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: isDismissible == false
                        ? DismissDirection.none
                        : DismissDirection.horizontal,
                    onDismissed: (_) => dismiss(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        child: Container(
                          padding:
                              padding ??
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            gradient: backgroundGradient,
                            borderRadius: BorderRadius.circular(
                              borderRadius ?? 16,
                            ),
                            border: Border.all(
                              color:
                                  borderColor ??
                                  scheme.outline.withValues(alpha: 0.18),
                              width: borderWidth ?? 1,
                            ),
                            boxShadow:
                                boxShadows ??
                                [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 30,
                                color: leftBarIndicatorColor ?? accentColor,
                              ),
                              const SizedBox(width: 10),
                              icon ??
                                  Icon(
                                    feedbackIcon,
                                    color: accentColor,
                                    size: 24,
                                  ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    titleText ??
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: foreground,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                    messageText ??
                                        Text(
                                          message,
                                          style: TextStyle(
                                            color: foreground.withValues(
                                              alpha: 0.72,
                                            ),
                                            fontSize: 13,
                                            height: 1.25,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              ?mainButton,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
    _timer = Timer(duration ?? const Duration(seconds: 2), dismiss);
  }
}
