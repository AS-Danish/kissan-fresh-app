import 'package:get/get.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/controllers/products_controller.dart';

class BottomBarBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<BottomBarController>(() => BottomBarController());
    Get.lazyPut<ProductsController>(() => ProductsController());
  }
}