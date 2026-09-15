import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../config/app_environment.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const MethodChannel _debugDeviceChannel = MethodChannel(
    'com.kissanfresh.app/debug-device',
  );
  bool _verificationSettingsApplied = false;

  // Verify Phone Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String) onCodeAutoRetrievalTimeout,
    required Function(PhoneAuthCredential)
    onVerificationCompleted, // For auto-verification
  }) async {
    await _configureDevelopmentPhoneVerification();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<void> _configureDevelopmentPhoneVerification() async {
    if (_verificationSettingsApplied ||
        !AppEnvironment.bypassPhoneVerificationOnEmulator) {
      return;
    }

    bool isEmulator = false;
    try {
      isEmulator =
          await _debugDeviceChannel.invokeMethod<bool>('isEmulator') ?? false;
    } on MissingPluginException {
      // Native channel additions are unavailable until a full Android rebuild.
      // Keep authentication usable instead of surfacing an implementation
      // exception when a developer has only hot-reloaded an older APK.
      return;
    }
    if (!isEmulator) return;

    await _auth.setSettings(appVerificationDisabledForTesting: true);
    _verificationSettingsApplied = true;
  }

  // Sign in with credential (for OTP + SMS Code or Auto-verification)
  Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  // Sign in with SMS Code
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Stream of Auth State Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
