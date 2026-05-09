import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kissanfresh/services/notification_service.dart';

class NotificationController extends GetxController {
  final _box = Hive.box('user_settings');
  final _key = 'isNotificationsEnabled';

  RxBool isNotificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    isNotificationsEnabled.value = _box.get(_key, defaultValue: true);
  }

  void toggleNotifications(bool value) async {
    isNotificationsEnabled.value = value;
    await _box.put(_key, value);
    
    if (value) {
      // Re-enable: request permission and save token
      await NotificationService().initialize();
    } else {
      // Disable: remove token from firestore
      await NotificationService().deleteTokenFromFirestore();
    }
  }
}
