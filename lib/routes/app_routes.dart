import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kissanfresh/features/catalog/domain/product_card_model.dart';
import 'package:kissanfresh/features/catalog/domain/section_model.dart';
import 'package:kissanfresh/core/layout/main_layout.dart';
import 'package:kissanfresh/features/cart/presentation/screens/cart_screen.dart';
import 'package:kissanfresh/features/catalog/presentation/screens/improved_home_screen.dart';
import 'package:kissanfresh/features/auth/presentation/screens/login_screen.dart';
import 'package:kissanfresh/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:kissanfresh/features/catalog/presentation/screens/product_details_screen.dart';
import 'package:kissanfresh/features/catalog/presentation/screens/search_screen.dart';
import 'package:kissanfresh/features/account/presentation/screens/settings_screen.dart';
import 'package:kissanfresh/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:kissanfresh/features/account/presentation/screens/profile_screen.dart';
import 'package:kissanfresh/features/delivery/presentation/screens/address_selection_screen.dart';
import 'package:kissanfresh/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:kissanfresh/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:kissanfresh/features/checkout/presentation/screens/payment_method_screen.dart';
import 'package:kissanfresh/core/screens/about_us_screen.dart';
import 'package:kissanfresh/core/screens/privacy_policy_screen.dart';
import 'package:kissanfresh/core/screens/terms_conditions_screen.dart';
import 'package:kissanfresh/core/screens/help_support_screen.dart';
import 'package:kissanfresh/core/screens/faq_screen.dart';
import 'package:kissanfresh/features/delivery/presentation/screens/slot_selection_screen.dart';
import 'package:kissanfresh/features/delivery/presentation/screens/manage_addresses_screen.dart';
import 'package:kissanfresh/features/catalog/presentation/screens/section_products_screen.dart';
import 'package:kissanfresh/features/account/presentation/screens/account_deletion_screen.dart';
import 'package:kissanfresh/features/checkout/presentation/screens/wallet_screen.dart';

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
  static const manageAddressesRoute = '/manage-addresses';
  static const paymentMethodRoute = '/payment-method';
  static const aboutUsRoute = '/about-us';
  static const privacyPolicyRoute = '/privacy-policy';
  static const termsConditionsRoute = '/terms-conditions';
  static const helpSupportRoute = '/help-support';
  static const faqRoute = '/faq';
  static const slotSelectionRoute = '/slot-selection';
  static const sectionProductsRoute = '/section-products';
  static const accountDeletionRoute = '/account-deletion';
  static const walletRoute = '/wallet';
  static Route<dynamic> generate(RouteSettings settings) =>
      CupertinoPageRoute(settings: settings, builder: (_) => page(settings));

  static Widget page(RouteSettings settings) {
    final signedIn = FirebaseAuth.instance.currentUser != null;
    var name = settings.name;
    if (signedIn && (name == loginScreen || name == otpVerificationRoute)) {
      name = mainLayout;
    } else if (!signedIn &&
        {profileRoute, accountDeletionRoute, walletRoute}.contains(name)) {
      name = loginScreen;
    }
    final args = settings.arguments;
    return switch (name) {
      mainLayout => const MainLayout(),
      homepageRoute => ImprovedHomeScreen(),
      wishlistRoute => const WishlistScreen(),
      searchRoute => const SearchScreen(),
      cartRoute => CartScreen(),
      myOrdersRoute => const MyOrdersScreen(),
      settingsRoute => SettingsScreen(),
      productDetailsRoute when args is ProductCardModel => ProductDetailsScreen(
        product: args,
      ),
      loginScreen => LoginScreen(),
      profileRoute => const ProfileScreen(),
      addressSelectionRoute => const AddressSelectionScreen(),
      otpVerificationRoute => OtpVerificationScreen(
        phoneNumber: args is String ? args : '',
      ),
      onboardingRoute => const OnboardingScreen(),
      manageAddressesRoute => const ManageAddressesScreen(),
      paymentMethodRoute => PaymentMethodScreen(),
      aboutUsRoute => const AboutUsScreen(),
      privacyPolicyRoute => const PrivacyPolicyScreen(),
      termsConditionsRoute => const TermsConditionsScreen(),
      helpSupportRoute => const HelpSupportScreen(),
      faqRoute => const FAQScreen(),
      slotSelectionRoute => const SlotSelectionScreen(),
      sectionProductsRoute when args is SectionModel => SectionProductsScreen(
        section: args,
      ),
      accountDeletionRoute => const AccountDeletionScreen(),
      walletRoute => const WalletScreen(),
      _ => const MainLayout(),
    };
  }
}
