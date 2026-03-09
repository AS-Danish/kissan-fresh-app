import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kissanfresh/services/maps_cache_service.dart';

class AddressController extends GetxController {
  // Observables
  var currentAddress = 'Move the map to select location'.obs;
  var selectedLocation = const LatLng(20.5937, 78.9629).obs;
  var isLoading = false.obs;
  var isLocationEnabled = false.obs;
  var predictions = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;

  // Google Maps Controller
  final Completer<GoogleMapController> mapCompleter = Completer();
  GoogleMapController? _mapController;

  final TextEditingController searchController = TextEditingController();

  final MapsCacheService _mapsCacheService = MapsCacheService();

  Timer? _geocodeDebounce;

  @override
  void onInit() {
    super.onInit();
    _checkPermission();
  }

  @override
  void onClose() {
    searchController.dispose();
    _geocodeDebounce?.cancel();
    _autocompleteDebounce?.cancel();
    _mapController?.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!mapCompleter.isCompleted) {
      mapCompleter.complete(controller);
    }
  }

  Future<void> _moveMap(LatLng latLng, {double zoom = 15.0}) async {
    final controller = await mapCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, zoom));
  }

  Future<void> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location Disabled', 'Please enable location services.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission Denied', 'Location permission is required.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied',
        'Enable location in app settings.',
        mainButton: TextButton(
          onPressed: () => Geolocator.openAppSettings(),
          child: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    isLocationEnabled.value = true;
    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    if (!isLocationEnabled.value) {
      await _checkPermission();
      if (!isLocationEnabled.value) return;
    }

    isLoading.value = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      selectedLocation.value = latLng;
      await _moveMap(latLng, zoom: 16.0);
      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Error getting location: $e');
      Get.snackbar('Error', 'Failed to get current location');
    } finally {
      isLoading.value = false;
    }
  }

  // Called when user explicitly taps map
  void onMapTap(LatLng position) {
    selectedLocation.value = position;
    currentAddress.value = 'Fetching address...';
    _reverseGeocode(position);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    _geocodeDebounce?.cancel();

    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
      isLoading.value = true;
      try {
        final address = await _mapsCacheService.reverseGeocode(point);
        if (address != null) {
          currentAddress.value = address;
        } else {
          currentAddress.value = 'Address not found';
        }
      } catch (e) {
        debugPrint('Reverse Geocoding Error: $e');
        currentAddress.value = 'Unable to fetch address';
      } finally {
        isLoading.value = false;
      }
    });
  }

  Timer? _autocompleteDebounce;

  void onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      predictions.clear();
      isSearching.value = false;
      return;
    }
    
    // Set searching to true and refresh the observers
    isSearching.value = true;
    
    _autocompleteDebounce?.cancel();
    _autocompleteDebounce = Timer(const Duration(milliseconds: 800), () async {
       final results = await _mapsCacheService.getAutocompletePredictions(query);
       predictions.value = results;
    });
  }

  Future<void> searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    isLoading.value = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final resultData = await _mapsCacheService.searchAddress(trimmed);
      if (resultData != null) {
        final latLng = LatLng(resultData['lat'], resultData['lng']);
        final address = resultData['address'];

        selectedLocation.value = latLng;
        currentAddress.value = address;
        searchController.text = address; // Update text field
        predictions.clear();
        isSearching.value = false;
        
        await _moveMap(latLng);
      } else {
        Get.snackbar('Not Found', 'No results for "$trimmed"');
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      Get.snackbar('Error', 'Failed to search address');
    } finally {
      isLoading.value = false;
    }
  }

  void confirmLocation() {
    final address = currentAddress.value;
    Get.back(result: {
      'address': address,
      'lat': selectedLocation.value.latitude,
      'lng': selectedLocation.value.longitude,
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.snackbar(
        'Location Updated',
        address,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0d9488),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    });
  }
}