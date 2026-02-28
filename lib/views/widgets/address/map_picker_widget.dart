import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../controllers/address_controller.dart';

class MapPickerWidget extends StatelessWidget {
  final AddressController controller;

  const MapPickerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GoogleMap(
      onMapCreated: controller.onMapCreated,
      initialCameraPosition: CameraPosition(
        target: controller.selectedLocation.value,
        zoom: 15.0,
      ),
      onCameraMove: controller.onCameraMove,
      onCameraIdle: controller.onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We use our own FAB
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      mapType: MapType.normal,
    ));
  }
}