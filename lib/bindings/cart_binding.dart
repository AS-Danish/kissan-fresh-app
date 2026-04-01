import 'package:get/get.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<CartController>(() => CartController());
  }
}
