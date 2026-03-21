import 'package:get/get.dart';
import 'package:kissanfresh/bindings/cart_binding.dart';
import 'package:kissanfresh/bindings/homepage_binding.dart';
import 'package:kissanfresh/bindings/my_orders_binding.dart';
import 'package:kissanfresh/bindings/product_details_binding.dart';
import 'package:kissanfresh/bindings/search_binding.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';
import 'package:kissanfresh/views/screens/cart_screen.dart';
import 'package:kissanfresh/views/screens/improved_home_screen.dart';
import 'package:kissanfresh/views/screens/login_screen.dart';
import 'package:kissanfresh/views/screens/my_orders_screen.dart';
import 'package:kissanfresh/views/screens/product_details_screen.dart';
import 'package:kissanfresh/views/screens/search_screen.dart';
import 'package:kissanfresh/views/screens/settings_screen.dart';
import 'package:kissanfresh/views/screens/wishlist_screen.dart';
import 'package:kissanfresh/views/screens/profile_screen.dart';
import 'package:kissanfresh/views/screens/address_selection_screen.dart';
import 'package:kissanfresh/views/screens/otp_verification_screen.dart';
import 'package:kissanfresh/views/screens/onboarding_screen.dart';
import 'package:kissanfresh/views/screens/payment_method_screen.dart';
import 'package:kissanfresh/views/screens/about_us_screen.dart';
import 'package:kissanfresh/views/screens/privacy_policy_screen.dart';
import 'package:kissanfresh/views/screens/terms_conditions_screen.dart';
import 'package:kissanfresh/views/screens/help_support_screen.dart';
import 'package:kissanfresh/bindings/onboarding_binding.dart';
import 'package:kissanfresh/middleware/auth_middleware.dart';

abstract class AppRoutes {
  static const auth = '/';
  static const mainLayout = '/main-layout';
  static const homepageRoute = '/home';
  static const wishlistRoute = '/wishlist';
  static const searchRoute = '/search-product';
  static const cartRoute = '/my-cart';
  static const myOrdersRoute = '/my-orders-page';
  static const settingsRoute = '/settings';
  static const productDetailsRoute = '/product-details';
  static const loginScreen = '/login-screen';
  static const profileRoute = '/profile';
  static const addressSelectionRoute = '/select-address';
  static const otpVerificationRoute = '/otp-verification';
  static const onboardingRoute = '/onboarding';
  static const paymentMethodRoute = '/payment-method';
  static const aboutUsRoute = '/about-us';
  static const privacyPolicyRoute = '/privacy-policy';
  static const termsConditionsRoute = '/terms-conditions';
  static const helpSupportRoute = '/help-support';
  static final pages = [
    GetPage(name: mainLayout, page: () => MainLayout()),
    GetPage(
      name: homepageRoute,
      page: () => ImprovedHomeScreen(),
      binding: HomepageBinding(),
    ),
    GetPage(
      name: wishlistRoute,
      page: () => const WishlistScreen(),
    ),
    GetPage(
      name: searchRoute,
      page: () => SearchScreen(),
      binding: SearchBinding(),
    ),
    GetPage(name: cartRoute, page: () => CartScreen(), binding: CartBinding()),
    GetPage(
      name: myOrdersRoute,
      page: () => MyOrdersScreen(),
      binding: MyOrdersBinding(),
    ),
    GetPage(name: settingsRoute, page: () => SettingsScreen()),
    GetPage(
      name: productDetailsRoute,
      page: () {
        final product = Get.arguments;
        return ProductDetailsScreen(product: product);
      },
      binding: ProductDetailsBinding(),
    ),
    GetPage(
      name: loginScreen, 
      page: () => LoginScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: profileRoute, 
      page: () => const ProfileScreen(),
      middlewares: [RequireAuthMiddleware()],
    ),
    GetPage(name: addressSelectionRoute, page: () => const AddressSelectionScreen()),
    GetPage(
      name: otpVerificationRoute, 
      page: () => OtpVerificationScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: onboardingRoute, page: () => const OnboardingScreen(), binding: OnboardingBinding()),
    GetPage(name: paymentMethodRoute, page: () => PaymentMethodScreen()),
    GetPage(name: aboutUsRoute, page: () => const AboutUsScreen()),
    GetPage(name: privacyPolicyRoute, page: () => const PrivacyPolicyScreen()),
    GetPage(name: termsConditionsRoute, page: () => const TermsConditionsScreen()),
    GetPage(name: helpSupportRoute, page: () => const HelpSupportScreen()),
  ];
}
