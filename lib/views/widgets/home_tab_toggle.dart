import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';

class HomeTabToggle extends StatelessWidget {
  const HomeTabToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Obx(() {
        final isGrocery =
            Get.find<HomepageController>().currentTab.value == 'Grocery';
        return Stack(
          children: [
            AnimatedAlign(
              alignment: isGrocery
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: Container(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Get.find<HomepageController>().switchTab('Grocery'),
                    behavior: HitTestBehavior.translucent,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_basket_rounded,
                            size: 16,
                            color: isGrocery
                                ? Colors.black
                                : Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Groceries",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isGrocery
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Get.find<HomepageController>().switchTab('HomeFood'),
                    behavior: HitTestBehavior.translucent,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 16,
                            color: !isGrocery
                                ? Colors.black
                                : Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Home Food",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: !isGrocery
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
