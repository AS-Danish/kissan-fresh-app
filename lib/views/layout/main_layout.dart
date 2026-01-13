import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/views/screens/homepage_screen.dart';

import '../../themes/app_theme.dart';
class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    BottomBarController barController = Get.find<BottomBarController>();

    List<Widget> _pages = [
      HomepageScreen(),
      Scaffold()
    ];
    return Scaffold(
      backgroundColor: AppTheme().backgroundColor,
      bottomNavigationBar: Obx(
            () => NavigationBar(
          onDestinationSelected: (value) {
            barController.currentIndex.value = value;
          },
          selectedIndex: barController.currentIndex.value,
          backgroundColor: AppTheme().secondaryColor,
          indicatorColor: AppTheme().primaryColor,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: barController.currentIndex.value == 0
                    ? Colors.white
                    : AppTheme().primaryColor,
              ),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.search,
                color: barController.currentIndex.value == 1
                    ? Colors.white
                    : AppTheme().primaryColor,
              ),
              label: "Explore Products",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: barController.currentIndex.value == 2
                    ? Colors.white
                    : AppTheme().primaryColor,
              ),
              label: "Cart",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings,
                color: barController.currentIndex.value == 3
                    ? Colors.white
                    : AppTheme().primaryColor,
              ),
              label: "Settings",
            ),
          ],
        ),
      ),
      body: Obx(() => _pages[barController.currentIndex.value]),
    );
  }
}
