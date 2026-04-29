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
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Orders',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.filterOptions.map((filter) {
                return Obx(() {
                  final isSelected = controller.selectedFilter.value == filter;
                  return InkWell(
                    onTap: () {
                      controller.setFilter(filter);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
