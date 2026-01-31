import 'package:get/get.dart';
import 'package:kissanfresh/controllers/products_controller.dart';

class ProductsControllerBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<ProductsController>(() => ProductsController());
  }
}