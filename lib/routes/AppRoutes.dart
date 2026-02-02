import 'package:get/get.dart';
import 'package:kissanfresh/bindings/cart_binding.dart';
import 'package:kissanfresh/bindings/homepage_binding.dart';
import 'package:kissanfresh/bindings/my_orders_binding.dart';
import 'package:kissanfresh/bindings/product_details_binding.dart';
import 'package:kissanfresh/bindings/search_binding.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';
import 'package:kissanfresh/views/screens/cart_screen.dart';
import 'package:kissanfresh/views/screens/improved_home_screen.dart';
import 'package:kissanfresh/views/screens/my_orders_screen.dart';
import 'package:kissanfresh/views/screens/product_details_screen.dart';
import 'package:kissanfresh/views/screens/search_screen.dart';
import 'package:kissanfresh/views/screens/settings_screen.dart';

abstract class AppRoutes {
  static const auth = '/';
  static const mainLayout = '/main-layout';
  static const homepageRoute = '/home';
  static const searchRoute = '/search-product';
  static const cartRoute = '/my-cart';
  static const myOrdersRoute = '/my-orders-page';
  static const settingsRoute = '/settings';
  static const productDetailsRoute = '/product-details';

  static final pages = [
    GetPage(
      name: mainLayout,
      page: () => MainLayout(),
    ),
    GetPage(
      name: homepageRoute,
      page: () => ImprovedHomeScreen(),
      binding: HomepageBinding(),
    ),
    GetPage(
      name: searchRoute,
      page: () => SearchScreen(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: cartRoute,
      page: () => CartScreen(),
      binding: CartBinding(),
    ),
    GetPage(
      name: myOrdersRoute,
      page: () => MyOrdersScreen(),
      binding: MyOrdersBinding(),
    ),
    GetPage(
      name: settingsRoute,
      page: () => SettingsScreen(),
    ),
    GetPage(
      name: productDetailsRoute,
      page: () {
        final product = Get.arguments;
        return ProductDetailsScreen(product: product);
      },
      binding: ProductDetailsBinding(),
    ),
  ];
}
