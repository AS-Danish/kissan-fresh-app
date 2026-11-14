import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/observable.dart';

T startController<T extends FeatureController>(Ref ref, T controller) {
  ref.onDispose(controller.onClose);
  controller.onInit();
  return controller;
}
