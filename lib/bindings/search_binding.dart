import 'package:get/get.dart';
import 'package:kissanfresh/controllers/product_search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<ProductSearchController>(() => ProductSearchController());
  }
}
