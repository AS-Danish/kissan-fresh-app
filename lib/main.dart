import 'package:kissanfresh/features/catalog/application/user_activity_controller.dart';
import 'package:kissanfresh/features/cart/application/cart_controller.dart';
import 'package:kissanfresh/core/controllers/theme_controller.dart';
import 'package:kissanfresh/features/delivery/data/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/navigation.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/routes/app_routes.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kissanfresh/core/screens/splash_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'package:kissanfresh/firebase_options.dart';
import 'package:kissanfresh/config/app_environment.dart';

import 'package:kissanfresh/features/account/data/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

// Plain `flutter run` and Android Studio's generated main.dart configuration
// intentionally start the isolated development environment. Production builds
// must use lib/main_prod.dart with --flavor prod.
Future<void> main() => bootstrap(AppFlavor.dev);

Future<void> bootstrap(AppFlavor flavor) async {
  AppEnvironment.flavor = flavor;
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (AppEnvironment.isDebug) {
    // The dev flavor must receive android/app/src/dev/google-services.json
    // from the separate debug Firebase project.
    await Firebase.initializeApp();
    if (Firebase.app().options.projectId == 'kissanfresh-a72c1') {
      throw StateError('The dev flavor cannot connect to production Firebase.');
    }
  } else {
    await Future.wait([
      dotenv.load(fileName: ".env"),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);
  }
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
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
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

  runApp(const ProviderScope(child: MyApp()));
  // Once Flutter UI is ready to paint, remove the native splash screen
  FlutterNativeSplash.remove();

  // Notifications are useful but not required for the first frame. Configure
  // them in the background and only show the permission prompt from Settings.
  unawaited(NotificationService().initialize(requestPermission: false));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    ref.watch(cartControllerProvider);
    ref.watch(locationServiceProvider);
    ref.watch(userActivityControllerProvider);
    return FieldBuilder(
      () => MaterialApp(
        navigatorKey: AppNavigator.key,
        scaffoldMessengerKey: AppNavigator.messengerKey,
        navigatorObservers: [AppNavigator.observer],
        debugShowCheckedModeBanner: false,
        title: AppEnvironment.appTitle,
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.themeMode,
        onGenerateRoute: AppRoutes.generate,
        home: const SplashScreen(),
      ),
    );
  }
}
