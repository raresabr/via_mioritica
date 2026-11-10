// lib/src/screens/splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../utils/app_colors.dart';
import 'force_update_screen.dart';
import 'root_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      // Faza 14: force-update gate — Remote Config was already fetched in
      // main() before runApp(), so this is a synchronous, instant check.
      final forceUpdateRequired = RemoteConfigService.isForceUpdateRequired;
      if (forceUpdateRequired) {
        // Faza 16: confirms a Remote Config force-update push actually
        // reaches real devices (visible in the Firebase Analytics console).
        AnalyticsService.logForceUpdateShown();
      }
      final destination = forceUpdateRequired
          ? const ForceUpdateScreen()
          : const RootNavScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => destination,
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terrain, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Via Mioritica',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Descoperă România pas cu pas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
