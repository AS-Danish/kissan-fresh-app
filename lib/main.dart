import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/views/screens/homepage_screen.dart';

void main() {
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
      home: HomepageScreen(),
    );
  }
}