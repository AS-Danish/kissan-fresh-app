import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/bindings/bottom_bar_binding.dart';
import 'package:kissanfresh/routes/app_routes.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';

import 'firebase_options.dart';

import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/controllers/address_controller.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/controllers/theme_controller.dart';
import 'package:kissanfresh/controllers/update_controller.dart';
import 'package:kissanfresh/controllers/user_activity_controller.dart';
import 'package:kissanfresh/controllers/orders_controller.dart';
import 'package:kissanfresh/services/cache_service.dart';
import 'package:kissanfresh/services/notification_service.dart';
import 'package:kissanfresh/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  

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
  Get.put(UpdateController(), permanent: true); // Check for updates immediately
  Get.put(LocationService(), permanent: true); // Add LocationService
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(AddressController(), permanent: true);
  Get.put(OrdersController(), permanent: true);
  Get.put(UserActivityController(), permanent: true);
  runApp(const MyApp());
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
        home: MainLayout(),
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
