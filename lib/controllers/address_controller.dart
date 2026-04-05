import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:kissanfresh/services/maps_cache_service.dart';

class AddressController extends GetxController {
  // Observables
  var currentAddress = 'Select delivery address'.obs;
  late Box _settingsBox;

  var selectedLocation = const LatLng(20.5937, 78.9629).obs;
  var isLoading = false.obs;
  var isLocationEnabled = false.obs;
  var predictions = <Map<String, dynamic>>[].obs;
  var isSearching = false.obs;
  var searchInput = ''.obs; // Mirror for searchController.text to satisfy Obx

  // Google Maps Controller
  Completer<GoogleMapController> mapCompleter = Completer();
  GoogleMapController? _mapController;

  final TextEditingController searchController = TextEditingController();

  final MapsCacheService _mapsCacheService = MapsCacheService();

  Timer? _geocodeDebounce;
  String _sessionToken = '';
  final _uuid = const Uuid();

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box('user_settings');
    _loadAddressFromHive();
    _refreshSessionToken();
    _checkPermission();
  }

  void _loadAddressFromHive() {
    final savedAddress = _settingsBox.get('current_address');
    if (savedAddress != null) {
      currentAddress.value = savedAddress;
      searchController.text = savedAddress;
    }
  }

  void _saveAddressToHive(String address) {
    _settingsBox.put('current_address', address);
  }

  void _refreshSessionToken() {
    _sessionToken = _uuid.v4();
    debugPrint('New Maps Session Token: $_sessionToken');
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
    if (_mapController == controller) return; // Already assigned
    
    _mapController = controller;
    if (mapCompleter.isCompleted) {
      mapCompleter = Completer();
    }
    mapCompleter.complete(controller);
    debugPrint('Google Map Created & Controller Assigned');
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
    update(['map-ui']);
  }

  Future<void> getCurrentLocation() async {
    if (!isLocationEnabled.value) {
      await _checkPermission();
      if (!isLocationEnabled.value) return;
    }

    isLoading.value = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      selectedLocation.value = latLng;
      await _moveMap(latLng, zoom: 16.0);
      await _reverseGeocode(latLng);
      update(['map-ui']);
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
    update(['map-ui']);
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
    searchInput.value = query; // Update observable for Obx
    if (query.trim().isEmpty) {
      predictions.clear();
      isSearching.value = false;
      _refreshSessionToken(); // Treat a clear as a new session start
      return;
    }

    // Set searching to true and refresh the observers
    isSearching.value = true;

    _autocompleteDebounce?.cancel();
    _autocompleteDebounce = Timer(const Duration(milliseconds: 800), () async {
      final results = await _mapsCacheService.getAutocompletePredictions(
        query,
        sessionToken: _sessionToken,
      );
      predictions.value = results;
    });
  }

  Future<void> searchAddress(String query, {String? placeId}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    isLoading.value = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      Map<String, dynamic>? resultData;

      if (placeId != null && placeId.isNotEmpty) {
        // High quality selection using Place Details (Efficient session usage)
        resultData = await _mapsCacheService.getPlaceDetails(
          placeId,
          sessionToken: _sessionToken,
        );
        // Session successfully "consumed" by a details call
        _refreshSessionToken();
      } else {
        // Fallback to basic geocoding for raw string searches
        resultData = await _mapsCacheService.searchAddress(trimmed);
      }

      if (resultData != null) {
        final latLng = LatLng(resultData['lat'], resultData['lng']);
        final address = resultData['address'];

        selectedLocation.value = latLng;
        currentAddress.value = address;
        searchController.text = address; // Update text field
        predictions.clear();
        isSearching.value = false;

        await _moveMap(latLng);
        update(['map-ui']);
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
    _saveAddressToHive(address);
    Get.back(
      result: {
        'address': address,
        'lat': selectedLocation.value.latitude,
        'lng': selectedLocation.value.longitude,
      },
    );

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
