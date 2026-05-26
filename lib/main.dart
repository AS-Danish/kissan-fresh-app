import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/bindings/bottom_bar_binding.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import 'package:kissanfresh/views/screens/splash_screen.dart';

import 'firebase_options.dart';

import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/controllers/address_controller.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/controllers/theme_controller.dart';
import 'package:kissanfresh/controllers/update_controller.dart';
import 'package:kissanfresh/controllers/user_activity_controller.dart';
import 'package:kissanfresh/controllers/notification_controller.dart';
import 'package:kissanfresh/controllers/orders_controller.dart';
import 'package:kissanfresh/services/cache_service.dart';
import 'package:kissanfresh/services/notification_service.dart';
import 'package:kissanfresh/utils/app_theme.dart';
import 'package:kissanfresh/utils/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  

  try {
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint("Firebase App Check activation failed: $e");
  }
  await Hive.initFlutter();
  await Hive.openBox('maps_cache');
  await Hive.openBox('cart_box');
  await Hive.openBox('user_settings'); // Add this for location service
  await Hive.openBox('wishlist_box');
  await Hive.openBox('orders_cache');
  await Hive.openBox('products_cache');
  await Hive.openBox('user_activity'); // Add this for personalized recommendations
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  Get.put(ThemeController()); // Initialize theme early
  Get.put(CacheService(), permanent: true); // Register CacheService
  final updateController = Get.put(UpdateController(), permanent: true); // Check for updates immediately
  final locationService = Get.put(LocationService(), permanent: true); // Add LocationService
  
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(AddressController(), permanent: true);
  Get.put(OrdersController(), permanent: true);
  Get.put(UserActivityController(), permanent: true);
  
  Get.put(NotificationController(), permanent: true);
  
  // Start initializing HomepageController as well
  final homepageController = Get.put(HomepageController(), permanent: true);

  // We call runApp immediately so the Get widget tree is mounted (required for navigation in UpdateController etc).
  // The UI is shown immediately with our custom splash screen.
  runApp(const MyApp());
  
  // Once Flutter UI is ready to paint, remove the native splash screen
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kissan Fresh',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        getPages: AppRoutes.pages,
        initialBinding: BottomBarBinding(),
        home: const SplashScreen(),
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 300),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Remove bottom padding so SafeArea inside routes doesn't double-pad
              padding: MediaQuery.of(context).padding.copyWith(bottom: 0),
              viewPadding: MediaQuery.of(context).viewPadding.copyWith(bottom: 0),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
