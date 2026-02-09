import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';

class AddressController extends GetxController {
  // Observables
  var currentAddress = 'Select Location'.obs;
  var selectedLocation = const LatLng(20.5937, 78.9629).obs; // Default to India center
  var isLoading = false.obs;
  var isLocationEnabled = false.obs;

  // Map Controller
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location Disabled', 'Please enable location services.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied', 'Location permission is required.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission Denied', 'Location permissions are permanently denied.');
      return;
    }

    isLocationEnabled.value = true;
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    if (!isLocationEnabled.value) {
      await _checkPermission();
      if (!isLocationEnabled.value) return;
    }

    isLoading.value = true;
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      selectedLocation.value = latLng;
      
      // Move map to location
      mapController.move(latLng, 15.0);
      
      // Get address for this location
      await getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint("Error getting location: $e");
      Get.snackbar('Error', 'Failed to get current location');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchAddress(String query) async {
    if (query.isEmpty) return;

    isLoading.value = true;
    // Using Nominatim OpenStreetMap API
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'KissanFreshApp/1.0', // Required by Nominatim
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'];

          final latLng = LatLng(lat, lon);
          selectedLocation.value = latLng;
          currentAddress.value = displayName; // Use the address from search result directly
          
          // Move map
          mapController.move(latLng, 15.0);
        } else {
          Get.snackbar('Not Found', 'Address not found');
        }
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      Get.snackbar('Error', 'Failed to search address');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAddressFromLatLng(LatLng point) async {
    // Reverse Geocoding via Nominatim
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'KissanFreshApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          currentAddress.value = data['display_name'];
        }
      }
    } catch (e) {
      debugPrint("Reverse Geocoding Error: $e");
    }
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    selectedLocation.value = point;
    getAddressFromLatLng(point);
  }

  void confirmLocation() {
    // Here you would save the address to user profile or global state
    // For now, we update the HomeHeader via a global state or callback
    // Assuming HomepageController or User Controller manages the home address
    // Let's assume we pass it back or update a global store
    
    Get.back(result: currentAddress.value); // Return the address
    Get.snackbar(
      'Location Updated',
      'Delivery location set to: ${currentAddress.value}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0d9488),
      colorText: Colors.white,
    );
  }
}
