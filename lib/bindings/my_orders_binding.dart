import 'package:get/get.dart';
import 'package:kissanfresh/controllers/orders_controller.dart';

class MyOrdersBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<OrdersController>(() => OrdersController());
  }
}
