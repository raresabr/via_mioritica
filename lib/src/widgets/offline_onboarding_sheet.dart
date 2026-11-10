// lib/src/widgets/offline_onboarding_sheet.dart
import 'package:flutter/material.dart';
import '../services/settings_box.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import 'design.dart';

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
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const OfflineOnboardingSheet(),
    );
    await SettingsBox.markOfflineOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.sun.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_for_offline_rounded,
                color: AppColors.sun600,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(S.offlineOnboardingTitle, style: displayStyle(26)),
            const SizedBox(height: 12),
            Text(
              S.offlineOnboardingBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(S.offlineOnboardingButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
