import 'package:kissanfresh/utils/custom_snackbar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/model/address_model.dart';
import 'package:kissanfresh/model/user_model.dart';
import 'package:kissanfresh/services/user_service.dart';
import 'package:kissanfresh/services/location_service.dart';
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
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController flatNoController = TextEditingController();

  final RxString selectedAddressType = 'Home'.obs; // Default to Home

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

    final flatNo = _settingsBox.get('current_flat_no');
    if (flatNo != null) {
      flatNoController.text = flatNo;
    }

    final landmark = _settingsBox.get('current_landmark');
    if (landmark != null) {
      landmarkController.text = landmark;
    }
  }

  void _saveAddressToHive(String address, String flatNo, String landmark) {
    _settingsBox.put('current_address', address);
    _settingsBox.put('current_flat_no', flatNo);
    _settingsBox.put('current_landmark', landmark);
  }

  void _refreshSessionToken() {
    _sessionToken = _uuid.v4();
    debugPrint('New Maps Session Token: $_sessionToken');
  }

  @override
  void onClose() {
    searchController.dispose();
    landmarkController.dispose();
    flatNoController.dispose();
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
      Get.defaultDialog(
        title: 'Location Disabled',
        middleText: 'Please turn on your GPS to fetch your delivery address.',
        textConfirm: 'Turn On',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        buttonColor: Get.theme.primaryColor,
        onConfirm: () async {
          Get.back();
          await Geolocator.openLocationSettings();
          // After returning from settings, wait a bit and check again
          Future.delayed(const Duration(seconds: 2), () {
            _checkPermission();
          });
        },
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomSnackBar.show(
          'Permission Denied',
          'Location permission is required.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      CustomSnackBar.show(
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
      CustomSnackBar.show('Error', 'Failed to get current location');
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
        CustomSnackBar.show('Not Found', 'No results for "$trimmed"');
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      CustomSnackBar.show('Error', 'Failed to search address');
    } finally {
      isLoading.value = false;
    }
  }

  void saveFinalAddress() {
    final flatNo = flatNoController.text.trim();
    final landmark = landmarkController.text.trim();
    final mapAddress = currentAddress.value;

    List<String> parts = [];
    if (flatNo.isNotEmpty) parts.add(flatNo);
    if (landmark.isNotEmpty) parts.add(landmark);
    parts.add(mapAddress);

    final finalAddress = parts.join(', ');

    _saveAddressToHive(finalAddress, flatNo, landmark);

    // Update the global location service with the new complete address
    if (Get.isRegistered<LocationService>()) {
      Get.find<LocationService>().currentAddress.value = finalAddress;

      // Update last_known_lat/lng so the auto-fetch doesn't immediately overwrite it
      _settingsBox.put('last_known_lat', selectedLocation.value.latitude);
      _settingsBox.put('last_known_lng', selectedLocation.value.longitude);
    }

    // Save to user profile if authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final newAddress = AddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: selectedAddressType.value,
        mapAddress: mapAddress,
        flatNo: flatNo.isNotEmpty ? flatNo : null,
        landmark: landmark.isNotEmpty ? landmark : null,
        latitude: selectedLocation.value.latitude,
        longitude: selectedLocation.value.longitude,
      );

      final userService = UserService();
      userService.getUser(currentUser.uid).then((userModel) {
        if (userModel != null) {
          final updatedAddresses = List<AddressModel>.from(
            userModel.savedAddresses,
          );
          updatedAddresses.add(newAddress);

          final updatedUser = UserModel(
            id: userModel.id,
            name: userModel.name,
            phoneNumber: userModel.phoneNumber,
            email: userModel.email,
            address: userModel.address,
            imageUrl: userModel.imageUrl,
            role: userModel.role,
            onboardingCompleted: userModel.onboardingCompleted,
            savedAddresses: updatedAddresses,
            createdAt: userModel.createdAt,
          );

          userService.updateUser(updatedUser);
        }
      });
    }

    // Clear the controllers for next time (they will be reloaded from Hive if edited)
    flatNoController.clear();
    landmarkController.clear();
    selectedAddressType.value = 'Home';

    // Pop the Details Screen
    Get.back();
    // Pop the Address Selection Screen and return the result to the original caller
    Get.back(
      result: {
        'address': finalAddress,
        'lat': selectedLocation.value.latitude,
        'lng': selectedLocation.value.longitude,
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      CustomSnackBar.show(
        'Location Updated',
        finalAddress,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    });
  }
}
