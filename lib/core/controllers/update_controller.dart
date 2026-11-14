import 'package:kissanfresh/features/catalog/application/categorized_products_controller.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';
import 'package:kissanfresh/core/services/cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kissanfresh/core/screens/force_update_screen.dart';

import 'dart:io';
import 'dart:math' as math;

class UpdateController extends FeatureController {
  final Ref ref;

  UpdateController(this.ref);

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Observable<bool> isCheckingForUpdate = Observable(false);
  Observable<bool> isUpdateAvailable = Observable(false);
  Observable<bool> isDownloading = Observable(false);

  bool isForceUpdateRequired = false;
  bool isServiceUnavailable = false;
  String serviceAvailableDateStr = '';

  Future<void>? initializationFuture;

  @override
  void onInit() {
    super.onInit();
    // Start update checks immediately
    initializationFuture = checkUpdates(showDialog: false);
  }

  Future<void> checkUpdates({bool showDialog = true}) async {
    await checkForceUpdate();
    await checkShorebirdUpdate(showDialog: showDialog);
  }

  /// Checks if a mandatory update is required via Play Store
  Future<void> checkForceUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final doc = await _firestore
          .collection('app_config')
          .doc('versioning')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // --- Added date of service check ---
        if (data.containsKey('date_of_service')) {
          final dynamic dateOfServiceRaw = data['date_of_service'];
          String dateStr = '';
          if (dateOfServiceRaw is Timestamp) {
            dateStr = dateOfServiceRaw.toDate().toIso8601String();
          } else if (dateOfServiceRaw != null) {
            dateStr = dateOfServiceRaw.toString();
          }

          if (dateStr.isNotEmpty) {
            final cacheService = ref.read(cacheServiceProvider);
            await cacheService.saveRaw('date_of_service', dateStr);

            final DateTime? serviceDate = DateTime.tryParse(dateStr);
            if (serviceDate != null && DateTime.now().isBefore(serviceDate)) {
              isServiceUnavailable = true;
              serviceAvailableDateStr = dateStr;
            }
          }
        }
        // ---------------------------------------------

        // --- Added check for remote catalog updates ---
        if (data.containsKey('catalog_status_last_updated_time')) {
          final dynamic catalogTimestampRaw =
              data['catalog_status_last_updated_time'];
          String remoteTimeStr = '';

          if (catalogTimestampRaw is Timestamp) {
            remoteTimeStr = catalogTimestampRaw.toDate().toIso8601String();
          } else if (catalogTimestampRaw != null) {
            remoteTimeStr = catalogTimestampRaw.toString();
          }

          if (remoteTimeStr.isNotEmpty) {
            final cacheService = ref.read(cacheServiceProvider);
            final localTimestamp = cacheService.getRaw(
              'local_catalog_timestamp',
            );

            if (localTimestamp != remoteTimeStr) {
              debugPrint("Catalog data changed on server, clearing cache...");
              await cacheService.clearCache();
              await cacheService.saveRaw(
                'local_catalog_timestamp',
                remoteTimeStr,
              );

              // Trigger a refresh if controllers are active
              if (ref.exists(homepageControllerProvider)) {
                ref.read(homepageControllerProvider).fetchCategories();
              }
              if (ref.exists(categorizedProductsControllerProvider)) {
                ref
                    .read(categorizedProductsControllerProvider)
                    .fetchCategorizedProducts();
              }
            }
          }
        }
        // ---------------------------------------------

        final String minVersion = data['min_version'] ?? '1.0.0';
        final String storeUrl = data['store_url'] ?? '';
        final bool forceUpdateEnabled = data['force_update'] ?? false;

        if (forceUpdateEnabled && _isVersionLower(currentVersion, minVersion)) {
          isForceUpdateRequired = true;
          AppNavigator.offAll(() => ForceUpdateScreen(storeUrl: storeUrl));
        }
      }
    } catch (e) {
      debugPrint("Error checking force update: $e");
    }
  }

  /// Checks for Shorebird OTA patches
  Future<void> checkShorebirdUpdate({bool showDialog = true}) async {
    if (kDebugMode) {
      debugPrint("UpdateController: Shorebird check skipped in debug mode.");
      return;
    }

    try {
      debugPrint("UpdateController: Checking for Shorebird updates...");
      final status = await _updater.checkForUpdate();
      debugPrint("UpdateController: Shorebird status: $status");

      if (status == UpdateStatus.outdated) {
        isUpdateAvailable.value = true;

        debugPrint("UpdateController: New patch found. Downloading...");
        isDownloading.value = true;
        await _updater.update();
        isDownloading.value = false;
        debugPrint("UpdateController: Patch downloaded successfully.");

        // Notify user to restart
        if (showDialog) {
          showRestartDialog();
        }
      } else {
        debugPrint("UpdateController: App is up to date.");
      }
    } catch (e) {
      debugPrint("UpdateController: Error checking Shorebird update: $e");
      isDownloading.value = false;
    }
  }

  void showRestartDialog() {
    AppNavigator.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppNavigator.theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: AppNavigator.theme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Ready!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A new update has been downloaded and is ready to be applied. Restart the app now to see the latest changes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => AppNavigator.back(),
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (defaultTargetPlatform == TargetPlatform.android) {
                          exit(0);
                        } else {
                          AppNavigator.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppNavigator.theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Restart Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  bool _isVersionLower(String current, String min) {
    List<int> currentParts = _parseVersion(current);
    List<int> minParts = _parseVersion(min);

    for (int i = 0; i < math.max(currentParts.length, minParts.length); i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      int minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) return true;
      if (currentPart > minPart) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    // Handle versions like "1.0.0+3" or "1.0.0-beta"
    String cleanVersion = version.split('+').first.split('-').first;
    return cleanVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  Future<void> launchStore(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final updateControllerProvider = Provider(
  (ref) => startController(ref, UpdateController(ref)),
);
