import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF5FFFE),
        elevation: 0,
        title: Text(
          'Complete Profile',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF2D3748),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide a few details to complete your registration.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: 'Full Name *',
              controller: controller.nameController,
              icon: Icons.person_outline,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Address *',
              controller: controller.addressController,
              icon: Icons.location_on_outlined,
              maxLines: 3,
              hint: 'Enter your delivery address',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email (Optional)',
              controller: controller.emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter your email address',
            ),
            const SizedBox(height: 48),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0d9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF0d9488).withOpacity(0.5),
                    ),
                    // ignore: prefer_const_constructors
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Complete Onboarding',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF9AA7AC), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                color: const Color(0xFFCBD5E0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
