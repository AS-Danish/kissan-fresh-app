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

      final box = Hive.box('user_settings');
      final double? lastLat = box.get('last_known_lat');
      final double? lastLng = box.get('last_known_lng');

      bool hasMovedSignificantly = true;
      if (lastLat != null && lastLng != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lastLat,
          lastLng,
        );
        // If distance is less than 150 meters, we consider it the same location
        if (distance <= 150) {
          hasMovedSignificantly = false;
        }
      }

      // Reverse geocode to get the GPS address
      final gpsAddress = await _mapsCacheService.reverseGeocode(latLng);

      if (hasMovedSignificantly) {
        // User physically moved. Discard manually saved address/flat details and use new GPS location.
        debugPrint('User moved significantly. Using new GPS location.');
        if (gpsAddress != null) {
          currentAddress.value = gpsAddress;
          
          await box.put('last_known_lat', position.latitude);
          await box.put('last_known_lng', position.longitude);
          await box.put('current_address', gpsAddress);
          await box.put('current_address_type', 'Current Location');
          currentAddressType.value = 'Current Location';
          
          // Clear old manual entries
          await box.delete('current_flat_no');
          await box.delete('current_landmark');
        }
      } else {
        // User is in the same location. Prefer the detailed address from Hive if it exists.
        final savedAddress = box.get('current_address');
        final savedType = box.get('current_address_type') ?? 'Current Location';
        
        if (savedAddress != null && savedAddress.toString().isNotEmpty) {
          currentAddress.value = savedAddress;
          currentAddressType.value = savedType;
          debugPrint('Using detailed saved address from Hive: $savedAddress');
        } else if (gpsAddress != null) {
          currentAddress.value = gpsAddress;
          currentAddressType.value = 'Current Location';
          await box.put('current_address', gpsAddress);
          await box.put('current_address_type', 'Current Location');
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
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

    debugPrint('Service Area Check: Distance is ${(distance / 1000).toStringAsFixed(2)} km');
    return distance <= maxServiceRadiusMeters;
  }
}
