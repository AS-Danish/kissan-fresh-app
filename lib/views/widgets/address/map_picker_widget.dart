import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kissanfresh/utils/app_theme.dart';
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
    _initialPosition = CameraPosition(
      target: widget.controller.selectedLocation.value,
      zoom: 15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GetBuilder<AddressController>(
      id: 'map-ui',
      builder: (controller) {
        return GoogleMap(
          key: const ValueKey('map_picker_stable'),
          style: isDarkMode ? AppTheme.darkMapStyle : null,
          onMapCreated: controller.onMapCreated,
          initialCameraPosition: _initialPosition,
          onTap: controller.onMapTap,
          markers: {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: controller.selectedLocation.value,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
        );
      },
    );
  }
}
