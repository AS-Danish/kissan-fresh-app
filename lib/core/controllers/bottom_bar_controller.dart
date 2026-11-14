import 'package:kissanfresh/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/observable.dart';

class BottomBarController extends FeatureController {
  Observable<int> currentIndex = Observable(0);

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

final bottomBarControllerProvider = Provider(
  (ref) => startController(ref, BottomBarController()),
);
