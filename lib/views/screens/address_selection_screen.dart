import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/address_controller.dart';
import '../widgets/address/map_picker_widget.dart';
import '../widgets/address/location_search_bar.dart';
import '../widgets/address/location_confirm_sheet.dart';

class AddressSelectionScreen extends StatelessWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddressController controller = Get.put(AddressController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF2D3748),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          MapPickerWidget(controller: controller),

          // Fixed center pin — stays still while map moves beneath it
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // offset so tip = center
              child: Icon(
                Icons.location_pin,
                size: 52,
                color: Color(0xFF0d9488),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: LocationSearchBar(controller: controller),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: controller.getCurrentLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF0d9488)),
            ),
          ),

          // Bottom Confirm Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LocationConfirmSheet(controller: controller),
          ),
        ],
      ),
    );
  }
}