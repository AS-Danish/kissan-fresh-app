import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/views/screens/cart_screen.dart';
import 'package:kissanfresh/views/screens/improved_home_screen.dart';
import 'package:kissanfresh/views/screens/my_orders_screen.dart';
import 'package:kissanfresh/views/screens/settings_screen.dart';
import '../../themes/app_theme.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    BottomBarController barController = Get.find<BottomBarController>();

    List<Widget> _pages = [
      ImprovedHomeScreen(),
      Scaffold(),
      CartScreen(),
      MyOrdersScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme().backgroundColor,
      bottomNavigationBar: Obx(
        () => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Home
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        label: "HOME",
                        index: 0,
                        barController: barController,
                        onTap: () => barController.currentIndex.value = 0,
                      ),
                      // Rewards
                      _buildNavItem(
                        icon: Icons.star_border,
                        label: "REWARDS",
                        index: 1,
                        barController: barController,
                        onTap: () => barController.currentIndex.value = 1,
                      ),
                      // Spacer for center button
                      SizedBox(width: 80),
                      // Menu
                      _buildNavItem(
                        icon: Icons.grid_view_outlined,
                        label: "MENU",
                        index: 3,
                        barController: barController,
                        onTap: () => barController.currentIndex.value = 3,
                      ),
                      // Profile
                      _buildNavItem(
                        icon: Icons.settings,
                        label: "SETTINGS",
                        index: 4,
                        barController: barController,
                        onTap: () => barController.currentIndex.value = 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Cart Button - Positioned ABOVE the bar
            Positioned(
              bottom: 25,
              child: _buildCenterCartButton(barController),
            ),
          ],
        ),
      ),
      body: Obx(() => _pages[barController.currentIndex.value]),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BottomBarController barController,
    required VoidCallback onTap,
  }) {
    bool isSelected = barController.currentIndex.value == index;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme().primaryColor
                  : Colors.grey.shade600,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme().primaryColor
                    : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCartButton(BottomBarController barController) {
    return InkWell(
      onTap: () => barController.currentIndex.value = 2,
      borderRadius: BorderRadius.circular(35),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFF14b8a6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme().primaryColor.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          // Badge
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
              child: Center(
                child: Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
