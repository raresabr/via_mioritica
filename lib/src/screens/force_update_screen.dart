// lib/src/screens/force_update_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_config_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';

/// Faza 14 — blocking screen shown instead of [RootNavScreen] when
/// [RemoteConfigService.isForceUpdateRequired] is true.
///
/// Deliberately has no back/dismiss path: wrapped in [PopScope] with
/// `canPop: false` so the Android back button can't bypass it, and there is
/// no navigation route to it other than replacing the whole stack from
/// `SplashScreen` — the only way out is updating (or closing the app).
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.tryParse(RemoteConfigService.storeUrl);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(S.forceUpdateStoreError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.sun.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 44,
                      color: AppColors.sun,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    S.forceUpdateTitle,
                    textAlign: TextAlign.center,
                    style: displayStyle(32, color: AppColors.cream),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    RemoteConfigService.forceUpdateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cream.withValues(alpha: 0.78),
                      fontSize: 16.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openStore(context),
                      child: const Text(S.forceUpdateButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
