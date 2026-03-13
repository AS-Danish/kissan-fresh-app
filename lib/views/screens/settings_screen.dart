import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';
import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/controllers/profile_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FFFE),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Profile Section
            _buildProfileSection(),

            const SizedBox(height: 24),

            // Account Settings
            _buildSectionHeader('Account'),
            _buildSettingsList([
              _SettingsItem(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'View your order history',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.location_on_outlined,
                title: 'Delivery Address',
                subtitle: 'Manage your addresses',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Manage payment options',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.favorite_outline,
                title: 'Wishlist',
                subtitle: 'Your favorite items',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 24),

            // Preferences
            _buildSectionHeader('Preferences'),
            _buildSettingsList([
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage your notifications',
                onTap: () {},
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: const Color(0xFF14b8a6),
                ),
              ),
              _SettingsItem(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Adjust your theme',
                onTap: () {},
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: const Color(0xFF14b8a6),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Support & Information
            _buildSectionHeader('Support & Information'),
            _buildSettingsList([
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and support',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'About Us',
                subtitle: 'Learn more about KissanFresh',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'View terms and conditions',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(),

            const SizedBox(height: 32),

            // App Version
            _buildAppVersion(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Obx(() {
      final user = AuthController.instance.firebaseUser.value;
      
      if (user == null) {
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.loginScreen),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.grey, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Unlock Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Login to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF718096)),
              ],
            ),
          ),
        );
      }

      final profileController = Get.put(ProfileController());

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() {
          if (profileController.isLoading.value) {
            return const SizedBox(
              height: 64, 
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0d9488))
              )
            );
          }
          return Row(
            children: [
              // Profile Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: profileController.profileImage.value.isEmpty 
                      ? null 
                      : Colors.transparent,
                  gradient: profileController.profileImage.value.isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: profileController.profileImage.value.isEmpty
                    ? Center(
                        child: Text(
                          profileController.initials.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          profileController.profileImage.value,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileController.name.value.isNotEmpty ? profileController.name.value : 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0d9488),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profileController.email.value.isNotEmpty ? profileController.email.value : 'No email added',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profileController.phoneNumber.value.isNotEmpty ? profileController.phoneNumber.value : user.phoneNumber ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Icon
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF0d9488),
                ),
                onPressed: () {
                  Get.toNamed(AppRoutes.profileRoute);
                },
              ),
            ],
          );
        }),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildSettingsList(List<_SettingsItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 60,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF14b8a6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF14b8a6),
                size: 22,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            subtitle: item.subtitle != null
                ? Text(
              item.subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF718096),
              ),
            )
                : null,
            trailing: item.trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF718096),
                ),
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final authController = AuthController.instance;
        final isLoggedIn = authController.firebaseUser.value != null;

        if (isLoggedIn) {
          // Show Logout
          return ElevatedButton(
            onPressed: () {
              // Trigger the true logout sequence which destroys Firebase session and redirects
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show Login
          return ElevatedButton(
            onPressed: () {
              Get.toNamed(AppRoutes.loginScreen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.login, size: 20),
                SizedBox(width: 8),
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'Version 1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF718096).withOpacity(0.7),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });
}