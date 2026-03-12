import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/address_controller.dart';

class LocationSearchBar extends StatelessWidget {
  final AddressController controller;

  const LocationSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 8.0),
                child: Icon(Icons.search, color: Colors.grey, size: 22),
              ),
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for building, street or area...',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => controller.searchAddress(value),
                ),
              ),
              Obx(() => controller.searchController.text.isNotEmpty || controller.isSearching.value
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.onSearchChanged('');
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    )
                  : const SizedBox(width: 16)),
            ],
          ),
        ),
        
        // Autocomplete Predictions Dropdown
        Obx(() {
          if (controller.predictions.isEmpty) return const SizedBox.shrink();
          
          return Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.predictions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final prediction = controller.predictions[index];
                  // Extract main text and secondary text if possible (Google usually separates these by comma)
                  final desc = prediction['description'] ?? '';
                  final parts = desc.split(', ');
                  final mainText = parts.isNotEmpty ? parts[0] : desc;
                  final secondaryText = parts.length > 1 ? parts.sublist(1).join(', ') : '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      radius: 16,
                      child: const Icon(Icons.location_on, color: Colors.grey, size: 18),
                    ),
                    title: Text(
                      mainText, 
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: secondaryText.isNotEmpty 
                      ? Text(
                          secondaryText,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      controller.searchAddress(
                        prediction['description'], 
                        placeId: prediction['place_id'],
                      );
                    },
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
