import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import '../../routes/AppRoutes.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomBarController barController = Get.find<BottomBarController>();

    // Route names for each tab
    final List<String> routes = [
      AppRoutes.homepageRoute,
      AppRoutes.wishlistRoute,
      AppRoutes.cartRoute,
      AppRoutes.myOrdersRoute,
      AppRoutes.settingsRoute,
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Obx(
            () => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24).copyWith(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context: context,
                        icon: Icons.home_outlined,
                        label: "HOME",
                        index: 0,
                        barController: barController,
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.favorite_border,
                        label: "Wishlist",
                        index: 1,
                        barController: barController,
                      ),
                      const SizedBox(width: 72),
                      _buildNavItem(
                        context: context,
                        icon: Icons.receipt_long,
                        label: "My Orders",
                        index: 3,
                        barController: barController,
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.settings,
                        label: "SETTINGS",
                        index: 4,
                        barController: barController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Cart Button
            Positioned(
              bottom: 25,
              child: _buildCenterCartButton(context, barController),
            ),
          ],
        ),
      ),
      // Use custom LazyTabBuilder to preserve state and lazy load with GetX routes
      body: Obx(() {
        return _LazyTabBuilder(
          currentIndex: barController.currentIndex.value,
          routes: routes,
        );
      }),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required BottomBarController barController,
  }) {
    bool isSelected = barController.currentIndex.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => barController.changePage(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCartButton(BuildContext context, BottomBarController barController) {
    return InkWell(
      onTap: () => barController.changePage(2),
      borderRadius: BorderRadius.circular(35),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          // Badge
          Obx(() {
            final cartController = Get.find<CartController>();
            if (cartController.totalItemCount == 0) return const SizedBox.shrink();
            
            return Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                child: Center(
                  child: Text(
                    '${cartController.totalItemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LazyTabBuilder extends StatefulWidget {
  final int currentIndex;
  final List<String> routes;

  const _LazyTabBuilder({
    Key? key,
    required this.currentIndex,
    required this.routes,
  }) : super(key: key);

  @override
  State<_LazyTabBuilder> createState() => _LazyTabBuilderState();
}

class _LazyTabBuilderState extends State<_LazyTabBuilder> {
  late final List<bool> _activatedPages;

  @override
  void initState() {
    super.initState();
    _activatedPages = List.generate(
      widget.routes.length,
      (index) => index == widget.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _LazyTabBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _activatedPages[widget.currentIndex] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: List.generate(widget.routes.length, (index) {
        if (_activatedPages[index]) {
          return _buildPage(widget.routes[index]);
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildPage(String routeName) {
    final routeDecoded = Get.routeTree.matchRoute(routeName);
    final page = routeDecoded.route;

    if (page == null) {
      return Center(child: Text('Route not found: $routeName'));
    }

    // Initialize binding if it exists and hasn't been initialized yet
    if (page.binding != null) {
      page.binding!.dependencies();
    }

    return page.page?.call() ?? const SizedBox.shrink();
  }
}
