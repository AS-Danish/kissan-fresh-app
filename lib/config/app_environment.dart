enum AppFlavor { prod, dev }

class AppEnvironment {
  AppEnvironment._();

  static AppFlavor flavor = AppFlavor.prod;
  static bool get isDebug => flavor == AppFlavor.dev;
  static String get appTitle => isDebug ? 'Kissan Fresh Debug' : 'Kissan Fresh';

  /// Development builds use a deterministic delivery point by default. This
  /// avoids requesting GPS permission or calling Google Maps while testing.
  /// Override with `--dart-define=USE_FIXED_DEBUG_LOCATION=false` when a
  /// developer explicitly wants to test the real location flow.
  static bool get useFixedDebugLocation =>
      isDebug &&
      const bool.fromEnvironment(
        'USE_FIXED_DEBUG_LOCATION',
        defaultValue: true,
      );

  static const double debugLatitude = 19.8887861;
  static const double debugLongitude = 75.3434361;
  static const String debugAddress =
      'Roshan Gate, Chhatrapati Sambhajinagar (Aurangabad), Maharashtra 431001';

  /// This only removes Android app-verification challenges on an emulator.
  /// Firebase test phone numbers and OTPs must still be configured server-side.
  static bool get bypassPhoneVerificationOnEmulator =>
      isDebug &&
      const bool.fromEnvironment(
        'BYPASS_PHONE_VERIFICATION_ON_EMULATOR',
        defaultValue: true,
      );

  // Razorpay key IDs are public client identifiers. The secret remains only in
  // Firebase Secret Manager and is never bundled into the application.
  static String get debugRazorpayKey => const String.fromEnvironment(
    'RAZORPAY_API_KEY',
    defaultValue: 'rzp_test_TcMH3wkKz6OSmw',
  );
}
