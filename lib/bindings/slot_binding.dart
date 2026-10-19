import 'package:get/get.dart';
import '../controllers/slot_selection_controller.dart';

class SlotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SlotSelectionController>(
      () => SlotSelectionController(),
      fenix: true,
    );
  }
}
