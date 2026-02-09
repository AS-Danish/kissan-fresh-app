import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import '../../routes/AppRoutes.dart';
import '../../themes/app_theme.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomBarController barController = Get.find<BottomBarController>();

    // Route names for each tab
    final List<String> routes = [
      AppRoutes.homepageRoute,
      AppRoutes.wishlistRoute,
      AppRoutes.cartRoute,
      AppRoutes.myOrdersRoute,
      AppRoutes.settingsRoute,
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
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
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        label: "HOME",
                        index: 0,
                        barController: barController,
                      ),
                      _buildNavItem(
                        icon: Icons.favorite_border,
                        label: "Wishlist",
                        index: 1,
                        barController: barController,
                      ),
                      const SizedBox(width: 80),
                      _buildNavItem(
                        icon: Icons.receipt_long,
                        label: "My Orders",
                        index: 3,
                        barController: barController,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        label: "SETTINGS",
                        index: 4,
                        barController: barController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Cart Button
            Positioned(
              bottom: 25,
              child: _buildCenterCartButton(barController),
            ),
          ],
        ),
      ),
      // Use IndexedStack to preserve state and lazy load with GetX routes
      body: Obx(() {
        return IndexedStack(
          index: barController.currentIndex.value,
          children: routes.map((route) {
            // Use GetBuilder to build each page with its binding
            return _buildPage(route);
          }).toList(),
        );
      }),
    );
  }

  /// Build a page with its proper binding
  Widget _buildPage(String routeName) {
    // Find the page in GetX routes
    final routeDecoded = Get.routeTree.matchRoute(routeName);
    final page = routeDecoded.route;

    if (page == null) {
      return Center(child: Text('Route not found: $routeName'));
    }

    // Initialize binding if it exists and hasn't been initialized yet
    if (page.binding != null) {
      page.binding!.dependencies();
    }

    // Return the page widget
    return page.page?.call() ?? Container();
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BottomBarController barController,
  }) {
    bool isSelected = barController.currentIndex.value == index;

    return InkWell(
      onTap: () => barController.changePage(index),
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
            const SizedBox(height: 4),
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
      onTap: () => barController.changePage(2),
      borderRadius: BorderRadius.circular(35),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF14b8a6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme().primaryColor.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: const Center(
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