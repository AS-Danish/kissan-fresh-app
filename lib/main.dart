import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/bindings/bottom_bar_binding.dart';
import 'package:kissanfresh/routes/AppRoutes.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';

import 'firebase_options.dart';

import 'package:kissanfresh/controllers/auth_controller.dart';
import 'package:kissanfresh/controllers/cart_controller.dart';
import 'package:kissanfresh/services/location_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox('maps_cache');
  await Hive.openBox('cart_box');
  await Hive.openBox('user_settings'); // Add this for location service
  await Hive.openBox('wishlist_box');
  Get.put(LocationService(), permanent: true); // Add LocationService
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kissan Fresh',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      getPages: AppRoutes.pages,
      initialBinding: BottomBarBinding(),
      home: MainLayout(),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}