import 'package:flutter/material.dart';

// Category model
class Category {
  final String name;
  final IconData icon;
  final bool isActive;

  Category({required this.name, required this.icon, this.isActive = false});
}

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Create the categories list here
  final List<Category> categories = [
    Category(name: "ALL", icon: Icons.apps, isActive: true),
    Category(name: "Vegetables", icon: Icons.local_florist),
    Category(name: "Fruits", icon: Icons.apple),
    Category(name: "Dairy", icon: Icons.egg),
    Category(name: "Meat", icon: Icons.dinner_dining),
    Category(name: "Bakery", icon: Icons.bakery_dining),
    Category(name: "Snacks", icon: Icons.cookie),
    Category(name: "Beverages", icon: Icons.local_cafe),
    Category(name: "Frozen", icon: Icons.ac_unit),
    Category(name: "Personal", icon: Icons.shopping_bag),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064e3b), Color(0xFF065e45)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivering to Home",
                            style: TextStyle(
                              color: Color(0xFF97e3c1),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "14 minutes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Danish, Azam Colony...",
                            style: TextStyle(
                              color: Color(0xFF6da692),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Color(0xFFbef264),
                        ),
                        onPressed: () {},
                        icon: Icon(
                          Icons.person_2_outlined,
                          color: Color(0xFF064e3b),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search \"organic vegetables\"",
                      hintStyle: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),

                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),

                      suffixIcon: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic, color: Color(0xFF10B981)),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: categoryIcons(categories[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/images/welcome_image.jpg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: -15,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C94C),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Text(
                      "OFFERS FOR YOU",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3A2E0F),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Column categoryIcons(Category category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: category.isActive
                ? Color(0xFFbef264)
                : Color(0xFF18624d),
          ),
          onPressed: () {},
          icon: Icon(
            category.icon,
            color: category.isActive ? Color(0xFF064e3b) : Color(0xFFb5cec7),
            size: 25,
          ),
        ),
        SizedBox(height: 5),
        Text(
          category.name,
          style: TextStyle(
            color: category.isActive ? Colors.white : Color(0xFFb3cbc5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
