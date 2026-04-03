import 'package:get/get.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import 'package:kissanfresh/controllers/best_seller_controller.dart';
import 'package:kissanfresh/controllers/categorized_products_controller.dart';

class HomepageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomepageController>(() => HomepageController());
    Get.lazyPut<BestsellersController>(() => BestsellersController());
    Get.lazyPut<CategorizedProductsController>(
      () => CategorizedProductsController(),
    );
  }
}
