import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/address_controller.dart';

class LocationConfirmSheet extends StatelessWidget {
  final AddressController controller;

  const LocationConfirmSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confirm Location',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF0d9488)),
                onPressed: controller.getCurrentLocation,
                tooltip: 'Use Current Location',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.currentAddress.value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )),
          const SizedBox(height: 20),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.confirmLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isLoading.value 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Text(
                    'Confirm Location',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          )),
        ],
      ),
    );
  }
}
