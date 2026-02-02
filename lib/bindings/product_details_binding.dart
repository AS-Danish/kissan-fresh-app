import 'package:get/get.dart';
import 'package:kissanfresh/controllers/product_details_controller.dart';

class ProductDetailsBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<ProductDetailsController>(() => ProductDetailsController());
  }
}