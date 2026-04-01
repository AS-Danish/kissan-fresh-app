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
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          MapPickerWidget(controller: controller),

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
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 4,
              onPressed: controller.getCurrentLocation,
              child: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
              ),
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
