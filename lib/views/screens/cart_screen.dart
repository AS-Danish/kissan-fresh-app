import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/address_controller.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import 'package:kissanfresh/views/widgets/cart/cart_summary_widget.dart';
import 'package:kissanfresh/views/widgets/cart/empty_cart_state.dart';
import 'package:kissanfresh/views/widgets/cart/delivery_info_card.dart';
import 'package:kissanfresh/views/widgets/cart/cart_item_tile.dart';
import 'package:kissanfresh/views/widgets/cart/clear_cart_dialog.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final CartController controller = Get.find<CartController>();
  final AddressController addressController = Get.put(AddressController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'My Cart',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => controller.cartItems.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                    onPressed: () {
                      ClearCartDialog.show(context, controller);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const EmptyCartState();
        }

        return Column(
          children: [
            // Delivery Info Card
            const DeliveryInfoCard(),

            const SizedBox(height: 16),

            // Cart Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.cartItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.cartItems[index];
                  return CartItemTile(
                    item: item,
                    controller: controller,
                  );
                },
              ),
            ),

            // Bottom Section with Price Summary and Checkout
            const CartSummaryWidget(),
          ],
        );
      }),
    );
  }
}
