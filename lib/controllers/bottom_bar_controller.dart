import 'package:get/get.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;

  /// Change the current page index
  void changePage(int index) {
    currentIndex.value = index;
  }

  /// Reset to home page
  void resetToHome() {
    currentIndex.value = 0;
  }

  /// Helper methods to navigate to specific tabs
  void goToHome() => changePage(0);
  void goToSearch() => changePage(1);
  void goToCart() => changePage(2);
  void goToOrders() => changePage(3);
  void goToSettings() => changePage(4);
}
