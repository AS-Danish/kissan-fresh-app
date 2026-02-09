import 'package:flutter/material.dart';
import '../../../controllers/address_controller.dart';

class LocationSearchBar extends StatelessWidget {
  final AddressController controller;

  const LocationSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: const InputDecoration(
                  hintText: 'Search address (e.g. Pune)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) => controller.searchAddress(value),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => controller.searchAddress(controller.searchController.text),
            ),
          ],
        ),
      ),
    );
  }
}
