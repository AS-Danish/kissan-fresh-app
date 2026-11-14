import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/features/delivery/application/address_controller.dart';
import 'package:kissanfresh/features/delivery/presentation/widgets/map_picker_widget.dart';
import 'package:kissanfresh/features/delivery/presentation/widgets/location_search_bar.dart';
import 'package:kissanfresh/features/delivery/presentation/widgets/location_confirm_sheet.dart';
import 'package:kissanfresh/config/app_environment.dart';

class AddressSelectionScreen extends ConsumerWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AddressController controller = ref.watch(addressControllerProvider);

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
          onPressed: () => AppNavigator.back(),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          MapPickerWidget(controller: controller),

          // Search Bar
          if (!AppEnvironment.useFixedDebugLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LocationSearchBar(controller: controller),
            ),

          // My Location FAB
          if (!AppEnvironment.useFixedDebugLocation)
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
