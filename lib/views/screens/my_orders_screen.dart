import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/orders_controller.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/views/widgets/orders/empty_orders_state.dart';
import 'package:kissanfresh/views/widgets/orders/order_card.dart';
import 'package:kissanfresh/views/widgets/orders/order_success_popup.dart';
import 'package:kissanfresh/views/widgets/floating_cart_snackbar.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrdersController controller = Get.find<OrdersController>();
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    // Check for success popup flag from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = Get.arguments;
      if (args is Map && args['showSuccessPopup'] == true && !_popupShown) {
        final orderType = args['orderType'] ?? 'Online';
        final paymentId = args['paymentId'];
        final orderId = args['orderId'];
        OrderSuccessPopup.show(
          context,
          orderType,
          paymentId,
          orderId: orderId,
        );
        _popupShown = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            size: 20,
          ),
          onPressed: () => Get.offAllNamed(AppRoutes.mainLayout),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return const EmptyOrdersState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return OrderCard(order: controller.orders[index]);
          },
        );
      }),
      bottomNavigationBar: const FloatingCartSnackbar(bottomPadding: 16.0),
    );
  }
}
