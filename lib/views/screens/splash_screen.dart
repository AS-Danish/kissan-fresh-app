import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissanfresh/controllers/homepage_controller.dart';
import 'package:kissanfresh/controllers/update_controller.dart';
import 'package:kissanfresh/services/location_service.dart';
import 'package:kissanfresh/views/layout/main_layout.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _textIndex = 0;
  final List<String> _loadingPhrases = [
    "Handpicking fresh produce...",
    "Connecting to local farms...",
    "Preparing your store...",
    "Almost ready..."
  ];

  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // Breathing effect

    _fadeAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Cycle text every 1.5 seconds to keep the user psychologically engaged
    _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingPhrases.length;
        });
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final updateController = Get.find<UpdateController>();
    final locationService = Get.find<LocationService>();
    final homepageController = Get.find<HomepageController>();

    try {
      // Run all background initializations concurrently, but we only WAIT for them
      // up to a maximum of 3 seconds. We don't want to block the user for long.
      // The home screen can handle missing data gracefully with its own loaders.
      final futures = <Future>[];
      
      if (updateController.initializationFuture != null) {
        futures.add(updateController.initializationFuture!);
      }
      if (locationService.initializationFuture != null) {
        futures.add(locationService.initializationFuture!);
      }
      if (homepageController.categoriesFuture != null) {
        futures.add(homepageController.categoriesFuture!);
      }

      // Minimum splash duration to show off the beautiful animation (1.5 seconds)
      futures.add(Future.delayed(const Duration(milliseconds: 1500)));

      // Wait for everything concurrently, but timeout after 3.5 seconds total to force app entry!
      // This massively speeds up startup on small devices by not waiting for slow operations.
      await Future.wait(futures).timeout(
        const Duration(milliseconds: 3500),
        onTimeout: () => [], // Ignore timeout and proceed to main layout
      );
    } catch (e) {
      debugPrint("Splash initialization handled error: $e");
    }

    if (mounted) {
      // Smooth fade transition into the app
      Get.offAll(() => MainLayout(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFefe8d6), // Beautiful cream/off-white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Breathing Logo Animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/KissanFreshCompleteLogo.png',
                width: 240,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_cart, 
                  size: 100, 
                  color: Color(0xFF14B8A6),
                ),
              ),
            ),
            
            const SizedBox(height: 70),
            
            // Custom modern sleek progress bar
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0x3314B8A6), // Transparent teal
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                  minHeight: 5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Psychological Animated Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _loadingPhrases[_textIndex],
                key: ValueKey<int>(_textIndex),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280), // Gray 500
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
