import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import '../../model/category_item_model.dart';

class CategoriesSection extends StatelessWidget {
  final HomepageController controller;

  const CategoriesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Obx(() {
        final selected = controller.selectedIndex.value;

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final item = controller.categories[index];
            final bool isSelected = selected == index;

            return GestureDetector(
              onTap: () => controller.selectCategory(index),
              child: _buildCategoryCard(item, isSelected),
            );
          },
        );
      }),
    );
  }

  Widget _buildCategoryCard(CategoryItemModel item, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0d9488) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF0d9488).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              item.icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 68,
          child: Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0d9488)
                  : Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}