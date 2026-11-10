// lib/src/screens/force_update_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_config_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

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
        backgroundColor: AppColors.green,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update,
                    size: 72,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    S.forceUpdateTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    RemoteConfigService.forceUpdateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _openStore(context),
                      child: const Text(
                        S.forceUpdateButton,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
