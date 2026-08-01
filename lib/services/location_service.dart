import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kissanfresh/services/maps_cache_service.dart';

class LocationService extends GetxService {
  final MapsCacheService _mapsCacheService = MapsCacheService();
  var currentLocation = Rxn<LatLng>();
  var currentAddress = RxnString();
  var currentAddressType = 'Current Location'.obs;
  var isLocationEnabled = false.obs;
  var locationPermissionDenied = false.obs;

  Future<void>? initializationFuture;

  // Service Area Configuration
  static const double serviceCenterLat = 19.8762;
  static const double serviceCenterLng = 75.3433;
  static const double maxServiceRadiusMeters = 30000; // 30km

  @override
  void onInit() {
    super.onInit();
    initializationFuture = _checkPermissionAndFetchLocation();
  }

  Future<void> _checkPermissionAndFetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      _showGPSPrompt();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        locationPermissionDenied.value = true;
        return;
      }
      // Add a small delay for the system to settle after dialog is dismissed
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      locationPermissionDenied.value = true;
      return;
    }

    locationPermissionDenied.value = false;
    isLocationEnabled.value = true;
    await fetchCurrentLocation();
  }

  Future<void> fetchCurrentLocation() async {
    final box = Hive.box('user_settings');
    try {
      // 1. Immediately load the saved address from Hive to populate UI instantly
      final savedAddress = box.get('current_address');
      final savedType = box.get('current_address_type') ?? 'Current Location';
      final double? lastLat = box.get('last_known_lat');
      final double? lastLng = box.get('last_known_lng');

      if (savedAddress != null && savedAddress.toString().isNotEmpty) {
        currentAddress.value = savedAddress;
        currentAddressType.value = savedType;
        if (lastLat != null && lastLng != null) {
          currentLocation.value = LatLng(lastLat, lastLng);
        }
        debugPrint('Instantly loaded saved address from Hive: $savedAddress');
      }

      // 2. Fetch the fresh GPS location asynchronously
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled before fetching.');
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          ).catchError((e) {
            debugPrint(
              'Fused Location Provider failed, trying balanced accuracy: $e',
            );
            return Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 10),
              ),
            );
          });

      final latLng = LatLng(position.latitude, position.longitude);
      currentLocation.value = latLng;

      bool hasMovedSignificantly = true;
      if (lastLat != null && lastLng != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lastLat,
          lastLng,
        );
        if (distance <= 150) {
          hasMovedSignificantly = false;
        }
      }

      if (hasMovedSignificantly) {
        debugPrint('User moved significantly. Using new GPS location.');
        final gpsAddress = await _mapsCacheService.reverseGeocode(latLng);
        
        if (gpsAddress != null) {
          currentAddress.value = gpsAddress;
          currentAddressType.value = 'Current Location';

          await box.put('last_known_lat', position.latitude);
          await box.put('last_known_lng', position.longitude);
          await box.put('current_address', gpsAddress);
          await box.put('current_address_type', 'Current Location');

          // Clear old manual entries
          await box.delete('current_flat_no');
          await box.delete('current_landmark');
        } else if (currentAddress.value == null) {
          currentAddress.value = 'Location Found (Address unavailable)';
          currentAddressType.value = 'Current Location';
        }
      } else {
        // User hasn't moved significantly.
        if (currentAddress.value == null) {
          final gpsAddress = await _mapsCacheService.reverseGeocode(latLng);
          if (gpsAddress != null) {
            currentAddress.value = gpsAddress;
            currentAddressType.value = 'Current Location';
            await box.put('current_address', gpsAddress);
            await box.put('current_address_type', 'Current Location');
            await box.put('last_known_lat', position.latitude);
            await box.put('last_known_lng', position.longitude);
          } else {
            currentAddress.value = 'Location Found (Address unavailable)';
            currentAddressType.value = 'Current Location';
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (currentAddress.value == null) {
        currentAddress.value = 'Location unavailable';
        currentAddressType.value = 'Unknown';
      }
    }
  }

  /// Checks if a given coordinate is within the serviceable area (30km radius from city center)
  bool isWithinServiceArea(double? lat, double? lng) {
    if (lat == null || lng == null) return false;

    final distance = Geolocator.distanceBetween(
      lat,
      lng,
      serviceCenterLat,
      serviceCenterLng,
    );

    debugPrint(
      'Service Area Check: Distance is ${(distance / 1000).toStringAsFixed(2)} km',
    );
    return distance <= maxServiceRadiusMeters;
  }

  void _showGPSPrompt() {
    // Ensure the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isDialogOpen == true) return;
      Get.defaultDialog(
        title: 'GPS is Disabled',
        middleText: 'Please turn on your GPS to fetch your delivery address.',
        textConfirm: 'Turn On',
        textCancel: 'Skip',
        confirmTextColor: Colors.white,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        buttonColor: Get.theme.primaryColor,
        onConfirm: () async {
          Get.back();
          await Geolocator.openLocationSettings();
          // Wait a bit for user to interact with settings, then re-check
          Future.delayed(const Duration(seconds: 2), () {
            _checkPermissionAndFetchLocation();
          });
        },
      );
    });
  }
}

