import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/bindings/bottom_bar_binding.dart';
import 'package:kissanfresh/controllers/bottom_bar_controller.dart';
import 'package:kissanfresh/routes/app_routes.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import 'package:kissanfresh/views/screens/splash_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Future.wait([
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  await Future.wait([
    Hive.openBox('maps_cache'),
    Hive.openBox('cart_box'),
    Hive.openBox('user_settings'),
    Hive.openBox('wishlist_box'),
    Hive.openBox('orders_cache'),
    Hive.openBox('products_cache'),
    Hive.openBox('user_activity'),
  ]);

  Get.put(ThemeController()); // Initialize theme early
  Get.put(CacheService(), permanent: true); // Register CacheService
  Get.put(UpdateController(), permanent: true); // Check for updates immediately
  Get.put(LocationService(), permanent: true); // Add LocationService

  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(AddressController(), permanent: true);
  Get.put(OrdersController(), permanent: true);
  Get.put(UserActivityController(), permanent: true);
  Get.put(BottomBarController(), permanent: true);

  Get.put(NotificationController(), permanent: true);

  // Start initializing HomepageController as well
  Get.put(HomepageController(), permanent: true);

  // We call runApp immediately so the Get widget tree is mounted (required for navigation in UpdateController etc).
  // The UI is shown immediately with our custom splash screen.
  runApp(const MyApp());

  // Once Flutter UI is ready to paint, remove the native splash screen
  FlutterNativeSplash.remove();

  // Notifications are useful but not required for the first frame. Configure
  // them in the background and only show the permission prompt from Settings.
  unawaited(NotificationService().initialize(requestPermission: false));
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
        theme: themeController.lightTheme,
        darkTheme: themeController.darkTheme,
        themeMode: themeController.themeMode,
        getPages: AppRoutes.pages,
        initialBinding: BottomBarBinding(),
        home: const SplashScreen(),
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
