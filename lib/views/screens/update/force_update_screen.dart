import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/update_controller.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String storeUrl;
  const ForceUpdateScreen({super.key, required this.storeUrl});

  @override
  Widget build(BuildContext context) {
    final UpdateController controller = Get.find<UpdateController>();

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon or Image
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update,
                    size: 80,
                    color: Color(0xFF14B8A6),
                  ),
                ),
                const SizedBox(height: 40),
                // Heading
                const Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message
                const Text(
                  'A newer version of Kissan Fresh is available. Please update the app from the Play Store to continue using our services.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => controller.launchStore(storeUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Update Now'),
                  ),
                ),
                const SizedBox(height: 20),
                // Optional message or branding
                const Text(
                  'Kissan Fresh - Freshness at your door!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
