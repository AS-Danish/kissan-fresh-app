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
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: widget.controller.selectedLocation.value,
      zoom: 15.0,
    );
  }

  void _updateMapStyle() {
    if (_mapController == null || !mounted) return;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _mapController!.setMapStyle(isDarkMode ? AppTheme.darkMapStyle : null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-check style on every build (triggered by theme changes)
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMapStyle());

    return Obx(() => GoogleMap(
      key: const ValueKey('map_picker_stable'),
      onMapCreated: (controller) {
        _mapController = controller;
        widget.controller.onMapCreated(controller);
        _updateMapStyle();
      },
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