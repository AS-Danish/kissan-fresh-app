import 'package:get/get.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';

class HomepageBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<HomepageController>(()=> HomepageController());
  }
}