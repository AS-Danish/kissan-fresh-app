import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatelessWidget {
  OtpVerificationScreen({super.key});

  final String phoneNumber = Get.arguments ?? '';

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.montserrat(
        fontSize: 20,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF0d9488), width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFFF0FDFA),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0d9488),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
             // Top Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a code to +91 $phoneNumber',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Section
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       const SizedBox(height: 32),
                       Text(
                        'Enter 6-digit code',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Pinput for OTP
                      Pinput(
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        controller: controller.otpController,
                        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                        showCursor: true,
                        onCompleted: (pin) {
                           controller.verifyOtp(pin);
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Verify Button
                      Obx(() => SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  controller.verifyOtp(controller.otpController.text);
                                },
                           style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d9488),
                            disabledBackgroundColor: const Color(0xFF0d9488).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Verify',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Resend Code
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive code? ",
                            style: GoogleFonts.montserrat(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          if (controller.resendTimer.value > 0)
                            Text(
                              "Resend in ${controller.resendTimer.value}s",
                              style: GoogleFonts.montserrat(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                controller.resendOtp(phoneNumber);
                              },
                              child: Text(
                                "Resend",
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF0d9488),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
