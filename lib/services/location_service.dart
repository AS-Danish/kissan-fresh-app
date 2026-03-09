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
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    isLocationEnabled.value = true;
    await fetchCurrentLocation();
  }

  Future<void> fetchCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
