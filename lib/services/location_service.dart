import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kissanfresh/services/maps_cache_service.dart';

class LocationService extends GetxService {
  final MapsCacheService _mapsCacheService = MapsCacheService();
  var currentLocation = Rxn<LatLng>();
  var currentAddress = RxnString();
  var isLocationEnabled = false.obs;
  var locationPermissionDenied = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkPermissionAndFetchLocation();
  }

  Future<void> _checkPermissionAndFetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
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
    try {
      // Re-check if service is still enabled
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

      // Reverse geocode to get the address
      final address = await _mapsCacheService.reverseGeocode(latLng);

      if (address != null) {
        currentAddress.value = address;

        // Save to local Hive box for global fast access if needed
        final box = Hive.box('user_settings');
        await box.put('last_known_lat', position.latitude);
        await box.put('last_known_lng', position.longitude);
        await box.put('last_known_address', address);

        debugPrint('Location fetched and saved: $address');
      }
    } catch (e) {
      debugPrint('Error getting location on startup: $e');
    }
  }
}
