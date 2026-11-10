// lib/src/widgets/offline_download_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_map_providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';

/// Card shown in the stage detail screen letting the user download the
/// trail corridor tiles for offline use, see progress, and delete the
/// cache. Shows an estimated size *before* starting the download (not
/// just progress after), per the offline UX requirement.
class OfflineDownloadCard extends ConsumerWidget {
  final String stageId;
  final String gpxAssetPath;

  const OfflineDownloadCard({
    super.key,
    required this.stageId,
    required this.gpxAssetPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (stageId: stageId, gpxAssetPath: gpxAssetPath);
    final state = ref.watch(offlineMapControllerProvider(args));
    final controller = ref.read(offlineMapControllerProvider(args).notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.night,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.sun,
              shape: const StadiumBorder(),
            ),
          ),
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: AppColors.sun,
            linearTrackColor: Colors.white.withValues(alpha: 0.14),
            linearMinHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sun,
              foregroundColor: AppColors.night,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.cream),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.sun.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_for_offline_rounded,
                      color: AppColors.sun,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.offlineSectionTitle,
                      style: displayStyle(19, color: AppColors.cream),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildBody(context, state, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OfflineDownloadState state,
    OfflineMapController controller,
  ) {
    switch (state.status) {
      case OfflineDownloadStatus.loading:
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case OfflineDownloadStatus.notDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              S.offlineNotDownloaded,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.estimateAndDownload,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text(S.offlineDownloadButton),
              ),
            ),
          ],
        );

      case OfflineDownloadStatus.estimating:
        return const Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(S.offlineEstimating, style: TextStyle(fontSize: 13)),
            ),
          ],
        );

      case OfflineDownloadStatus.downloading:
      case OfflineDownloadStatus.paused:
        final percent = state.progressPercent ?? 0;
        final estimatedMb = state.estimatedTileCount != null
            ? (state.estimatedTileCount! * 18 / 1024).toStringAsFixed(1)
            : '–';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.status == OfflineDownloadStatus.paused
                  ? S.offlinePaused
                  : S.offlineDownloading,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: percent / 100),
            const SizedBox(height: 4),
            Text(
              '${percent.toStringAsFixed(0)}% · ~$estimatedMb MB',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            // UI/UX polish: buttons on their own Wrap-able row, left
            // aligned, so long labels never get cramped/clipped next to
            // each other on narrow screens.
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: state.status == OfflineDownloadStatus.paused
                      ? controller.resume
                      : controller.pause,
                  child: Text(
                    state.status == OfflineDownloadStatus.paused
                        ? S.offlineResumeButton
                        : S.offlinePauseButton,
                  ),
                ),
                TextButton(
                  onPressed: controller.cancelAndDelete,
                  child: const Text(S.offlineCancelButton),
                ),
              ],
            ),
          ],
        );

      case OfflineDownloadStatus.interrupted:
        // Faza 21 — the app was likely killed/crashed mid-download last
        // time; FMTC's recovery data lets us resume from the last
        // successfully downloaded tile instead of starting over.
        final resumePercent = state.progressPercent ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.offlineInterrupted,
              style: const TextStyle(fontSize: 13, color: AppColors.sun300),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: resumePercent / 100),
            const SizedBox(height: 4),
            Text(
              '${resumePercent.toStringAsFixed(0)}% completă',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.resumeInterrupted,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(S.offlineResumeDownloadButton),
                ),
                TextButton(
                  onPressed: controller.cancelAndDelete,
                  child: const Text(S.offlineCancelButton),
                ),
              ],
            ),
          ],
        );

      case OfflineDownloadStatus.complete:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.offlineComplete} '
              '(${state.cachedTileCount} tile-uri, '
              '~${state.cachedSizeMb.toStringAsFixed(1)} MB)',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.sun,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.deleteCache,
                child: const Text(S.offlineDeleteButton),
              ),
            ),
          ],
        );

      case OfflineDownloadStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.errorMessage ?? S.offlineError,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF9C94)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.estimateAndDownload,
                child: const Text(S.offlineRetryButton),
              ),
            ),
          ],
        );
    }
  }
}
