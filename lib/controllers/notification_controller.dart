import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kissanfresh/services/notification_service.dart';
import 'package:kissanfresh/utils/custom_snackbar.dart';

class NotificationController extends GetxController {
  final _box = Hive.box('user_settings');
  final _key = 'isNotificationsEnabled';

  final RxBool isNotificationsEnabled = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    _syncWithSystemPermission();
  }

  Future<void> _syncWithSystemPermission() async {
    final preferenceEnabled =
        _box.get(_key, defaultValue: true) as bool;
    try {
      final hasPermission = await NotificationService()
          .hasNotificationPermission();
      final enabled = preferenceEnabled && hasPermission;
      isNotificationsEnabled.value = enabled;
      if (preferenceEnabled != enabled) await _box.put(_key, enabled);
    } catch (_) {
      isNotificationsEnabled.value = false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    if (isUpdating.value || value == isNotificationsEnabled.value) return;
    isUpdating.value = true;

    try {
      if (!value) {
        isNotificationsEnabled.value = false;
        await _box.put(_key, false);
        await NotificationService().deleteTokenFromFirestore();
        return;
      }

      // Keep the switch off while the OS permission dialog is open. Only the
      // permission result—not the tap itself—may enable notifications.
      final permissionGranted = await NotificationService()
          .requestNotificationPermission();
      if (!permissionGranted) {
        isNotificationsEnabled.value = false;
        await _box.put(_key, false);
        CustomSnackBar.warning(
          'Notifications remain off',
          'Permission was not granted. You can enable it later from device settings.',
        );
        return;
      }

      await _box.put(_key, true);
      isNotificationsEnabled.value = true;
      await NotificationService().enableNotifications();
      CustomSnackBar.success(
        'Notifications enabled',
        'Order updates and offers are now turned on.',
      );
    } catch (_) {
      isNotificationsEnabled.value = false;
      await _box.put(_key, false);
      CustomSnackBar.error(
        'Could not enable notifications',
        'Please try again in a moment.',
      );
    } finally {
      isUpdating.value = false;
    }
  }
}
