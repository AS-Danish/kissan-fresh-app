import 'package:kissanfresh/utils/custom_snackbar.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static Future<bool> isConnected() async {
    try {
      bool result = await InternetConnection().hasInternetAccess.timeout(
        const Duration(seconds: 2),
      );
      return result;
    } catch (e) {
      // If the check times out or fails, default to true 
      // so we don't block the user. Firebase will throw an error if offline anyway.
      return true;
    }
  }

  static void showNoInternetSnackbar() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    CustomSnackBar.show(
      "No Internet Connection",
      "Please check your internet connection and try again.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }
}
