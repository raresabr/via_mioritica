// lib/src/screens/splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import 'force_update_screen.dart';
import 'root_nav_screen.dart';

/// Matches the native launch background (see `launch_background.xml` and
/// `LaunchScreen.storyboard`) so there is no colour flash before Flutter draws.
const _parchment = Color(0xFFCDAD81);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const splashImageAsset = 'assets/images/splash.webp';

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
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

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
      backgroundColor: _parchment,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              SplashScreen.splashImageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: S.appName,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
