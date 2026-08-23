import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    final RxBool isButtonEnabled = false.obs;

    controller.phoneController.addListener(() {
      isButtonEnabled.value = controller.phoneController.text.length == 10;
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Illustration / Branding area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface, // Match scaffold
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Premium Logo Container
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.shopping_basket_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 72,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            "India's last minute app",
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color ??
                                  Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Log in or sign up",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7) ??
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Phone Input Card Area
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Country Code
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+91',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color ??
                                          Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 24,
                                    width: 1.5,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ],
                              ),
                            ),
                            // Input Field
                            Expanded(
                              child: TextField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      Colors.black87,
                                  letterSpacing: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter mobile number',
                                  hintStyle: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.5) ??
                                        Colors.grey.shade400,
                                    letterSpacing: 0,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(
                                    right: 16,
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Obx(
                        () => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isButtonEnabled.value
                                ? () {
                                    Get.dialog(
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Sending OTP...',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color ??
                                                      Colors.black87,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      barrierDismissible: false,
                                    );
                                    controller.sendOtp();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isButtonEnabled.value
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer Terms
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                        Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms of service',
                      style: GoogleFonts.montserrat(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy policy',
                      style: GoogleFonts.montserrat(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
