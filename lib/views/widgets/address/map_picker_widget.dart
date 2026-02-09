import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../controllers/address_controller.dart';

class MapPickerWidget extends StatelessWidget {
  final AddressController controller;

  const MapPickerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.selectedLocation.value,
        initialZoom: 15.0,
        onTap: controller.onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.kissanfresh',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: controller.selectedLocation.value,
              width: 80,
              height: 80,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    ));
  }
}
