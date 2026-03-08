import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());
    
    final RxBool isButtonEnabled = false.obs;
    controller.phoneController.addListener(() {
      isButtonEnabled.value = controller.phoneController.text.length == 10;
    });

    return Scaffold(
      backgroundColor: Colors.white, // Ensure bottom safe area is white
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(), // Prevents bouncing to reveal background above top
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                // Top Section (Teal Background with abstract circles)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF0d9488),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        // Decorative Elements
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        // Top Content
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          child: _buildTopSection(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section (White Card overlapping)
                Expanded(
                  child: Container(
                    color: const Color(0xFF0d9488), // Match top so curve is smooth
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                          child: _buildLoginForm(controller, isButtonEnabled),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Identity
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.eco_rounded, 
            color: Color(0xFF0d9488),
            size: 54,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Kissan Fresh',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        
        const SizedBox(height: 12),

        Text(
          'Delivering farm-fresh grocery\ndirectly to your doorstep.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.95),
            height: 1.4,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthController controller, RxBool isButtonEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to fresh!',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your mobile number to continue',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(height: 48),

        // Phone Number Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0d9488).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Country Code part
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🇮🇳',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+91',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
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
                    color: Colors.black87,
                    letterSpacing: 2.0,
                  ),
                  decoration: InputDecoration(
                    hintText: '00000 00000',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade300,
                      letterSpacing: 2.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // OTP Button
        Obx(() => Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isButtonEnabled.value
                ? [
                    BoxShadow(
                      color: const Color(0xFF0d9488).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: isButtonEnabled.value ? controller.sendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              disabledBackgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isButtonEnabled.value ? Colors.white : Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isButtonEnabled.value) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ]
              ],
            ),
          ),
        )),
        
        const Spacer(),

        // Bottom Footer (Sign Up & Terms)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'New to the app? ',
                    style: GoogleFonts.montserrat(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.montserrat(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0d9488),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our\n',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: Colors.grey.shade500,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0d9488),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0d9488),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}