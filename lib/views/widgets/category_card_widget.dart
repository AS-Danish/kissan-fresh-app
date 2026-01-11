import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/model/category_card_model.dart';

import '../../themes/app_theme.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryCardModel categories;
  const CategoryCardWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          padding: EdgeInsets.all(20),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme().secondaryColor,
            alignment: Alignment.center,
            side: BorderSide(color: AppTheme().secondaryTextColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: categories.onTap,
          icon: Icon(categories.icon),
        ),
        SizedBox(height: 10),
        Text(
          categories.title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme().primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
