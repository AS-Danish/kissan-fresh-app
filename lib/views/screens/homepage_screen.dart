import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/model/promotional_card_model.dart';
import 'package:kissanfresh/themes/app_theme.dart';
import 'package:kissanfresh/views/widgets/category_card_widget.dart';
import 'package:kissanfresh/views/widgets/promotional_card_widget.dart';
import '../../model/category_card_model.dart';

class HomepageScreen extends StatelessWidget {
  const HomepageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CategoryCardModel> categories = [
      CategoryCardModel(
        icon: Icons.energy_savings_leaf_sharp,
        title: "Veggies",
        onTap: () {},
      ),
      CategoryCardModel(icon: Icons.icecream, title: "Snacks", onTap: () {}),
      CategoryCardModel(
        icon: Icons.wine_bar_rounded,
        title: "Drinks",
        onTap: () {},
      ),
      CategoryCardModel(
        icon: Icons.clean_hands_rounded,
        title: "Care",
        onTap: () {},
      ),
      CategoryCardModel(
        icon: Icons.fastfood_rounded,
        title: "Meat",
        onTap: () {},
      ),
      CategoryCardModel(
        icon: Icons.cleaning_services_rounded,
        title: "Cleaning",
        onTap: () {},
      ),
      CategoryCardModel(
        icon: Icons.local_florist_rounded,
        title: "Fruits",
        onTap: () {},
      ),
      CategoryCardModel(
        icon: Icons.breakfast_dining_rounded,
        title: "Bakery",
        onTap: () {},
      ),
    ];

    final List<PromotionalCardModel> promotionCard = [
      PromotionalCardModel(
        titleText: "Organic Harvest Flat 30% Off",
        btnText: "SHOP FRESH",
        onTap: () {},
      ),
      PromotionalCardModel(
        titleText: "Daily Essentials in Minutes",
        btnText: "BUY NOW",
        onTap: () {},
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme().backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme().primaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.location_pin, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Delivery in 12-18 mins",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme().primaryColor,
                          ),
                        ),
                        Text(
                          "Home - Forest Residency, Sector 45",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme().primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme().secondaryColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme().primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                buildTextField(),
                SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: promotionCard.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PromotionalCardWidget(
                          promotionCard: promotionCard[index],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Forest Categories",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme().primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "View All",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme().primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                //Category Card
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return CategoryCardWidget(categories: categories[index]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextField buildTextField() {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme().secondaryColor.withOpacity(0.5),
        hintText: "Search Organic Groceries...",
        hintStyle: TextStyle(color: AppTheme().secondaryTextColor),
        prefixIcon: Icon(
          Icons.search,
          color: AppTheme().primaryColor,
          fontWeight: FontWeight.w900,
        ),
        suffixIcon: Icon(
          Icons.keyboard_voice_rounded,
          color: AppTheme().primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppTheme().primaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppTheme().primaryTextColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
    );
  }
}
