import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/features/delivery/application/address_controller.dart';
import 'package:kissanfresh/features/cart/application/cart_controller.dart';
import 'package:kissanfresh/features/cart/presentation/widgets/cart_summary_widget.dart';
import 'package:kissanfresh/features/cart/presentation/widgets/empty_cart_state.dart';
import 'package:kissanfresh/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:kissanfresh/features/cart/presentation/widgets/clear_cart_dialog.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  late final CartController controller = ref.read(cartControllerProvider);
  late final AddressController addressController = ref.read(
    addressControllerProvider,
  );

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
          FieldBuilder(
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
      body: FieldBuilder(() {
        if (controller.cartItems.isEmpty) {
          return const EmptyCartState();
        }

        return Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  top: 16,
                ),
                itemCount: controller.cartItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.cartItems[index];
                  return CartItemTile(item: item, controller: controller);
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
