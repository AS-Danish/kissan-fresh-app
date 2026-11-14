import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kissanfresh/core/utils/app_theme.dart';
import 'package:kissanfresh/features/delivery/application/address_controller.dart';
import 'package:kissanfresh/config/app_environment.dart';

class MapPickerWidget extends ConsumerStatefulWidget {
  final AddressController controller;

  const MapPickerWidget({super.key, required this.controller});

  @override
  ConsumerState<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends ConsumerState<MapPickerWidget> {
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
    if (AppEnvironment.useFixedDebugLocation) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Fixed debug location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppEnvironment.debugAddress,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppEnvironment.debugLatitude}, ${AppEnvironment.debugLongitude}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FieldBuilder(() {
      final controller = ref.read(addressControllerProvider);
      controller.changes.value;
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
    });
  }
}
