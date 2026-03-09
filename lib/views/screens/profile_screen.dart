import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FFFE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0d9488)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                   Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0d9488).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Obx(() => controller.profileImage.value.isEmpty
                        ? const Center(
                            child: Text(
                              'JD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              controller.profileImage.value,
                              fit: BoxFit.cover,
                            ),
                          )),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: controller.pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF0d9488),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              label: 'Full Name',
              controller: controller.nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email Address (Optional)',
              controller: controller.emailController,
              icon: Icons.email_outlined,
              isReadOnly: false, 
            ),
            const SizedBox(height: 16),
             _buildTextField(
              label: 'Phone Number',
              controller: controller.phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isReadOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Address',
              controller: controller.addressController,
              icon: Icons.location_on_outlined,
              maxLines: 3,
              isReadOnly: true,
              onTap: () async {
                final result = await Get.toNamed(AppRoutes.addressSelectionRoute);
                if (result != null && result is Map<String, dynamic>) {
                   controller.addressController.text = result['address'] ?? '';
                }
              }
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d9488),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF0d9488).withOpacity(0.5),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Delete Account Button
             SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: controller.deleteAccount,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onTap,
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
            readOnly: isReadOnly,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onTap: onTap,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isReadOnly && onTap == null ? Colors.grey.shade600 : Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF9AA7AC), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
