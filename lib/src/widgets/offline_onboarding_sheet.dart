// lib/src/widgets/offline_onboarding_sheet.dart
import 'package:flutter/material.dart';
import '../services/settings_box.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

/// Faza 20 — one-time onboarding tip pointing new users at the offline
/// map download feature (Faza 2b), shown once on the first app launch
/// (from `RootNavScreen`). Mountain trails frequently have zero signal, so
/// this exists to make sure users know *before* they start hiking that
/// they should download the corridor map for their stage(s) while still
/// online, rather than discovering the gap only once already offline.
class OfflineOnboardingSheet extends StatelessWidget {
  const OfflineOnboardingSheet({super.key});

  /// Shows the sheet at most once ever — checks/sets the
  /// `SettingsBox.hasSeenOfflineOnboarding` flag itself, so callers can
  /// unconditionally call this on every app start without extra checks.
  static Future<void> showIfFirstLaunch(BuildContext context) async {
    if (SettingsBox.hasSeenOfflineOnboarding) return;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const OfflineOnboardingSheet(),
    );
    await SettingsBox.markOfflineOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.download_for_offline_outlined,
                color: AppColors.green, size: 40),
            const SizedBox(height: 12),
            const Text(
              S.offlineOnboardingTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              S.offlineOnboardingBody,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(S.offlineOnboardingButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
