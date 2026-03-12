import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../controllers/address_controller.dart';

class MapPickerWidget extends StatefulWidget {
  final AddressController controller;

  const MapPickerWidget({super.key, required this.controller});

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    // Capture the starting location once to prevent re-initializing the map's 
    // initial state on every reactive update (which could count as multiple sessions)
    _initialPosition = CameraPosition(
      target: widget.controller.selectedLocation.value,
      zoom: 15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GoogleMap(
      onMapCreated: widget.controller.onMapCreated,
      initialCameraPosition: _initialPosition,
      onTap: widget.controller.onMapTap,
      markers: {
        Marker(
          markerId: const MarkerId('selected-location'),
          position: widget.controller.selectedLocation.value,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      mapType: MapType.normal,
    ));
  }
}