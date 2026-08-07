// lib/src/widgets/offline_download_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_map_providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_for_offline_outlined,
                    color: AppColors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  S.offlineSectionTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildBody(context, state, controller),
          ],
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
        return Row(
          children: [
            Expanded(
              child: Text(
                S.offlineNotDownloaded,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            ElevatedButton.icon(
              onPressed: controller.estimateAndDownload,
              icon: const Icon(Icons.download, size: 16),
              label: const Text(S.offlineDownloadButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
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
              child: Text(S.offlineEstimating,
                  style: TextStyle(fontSize: 13)),
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
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
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

      case OfflineDownloadStatus.complete:
        return Row(
          children: [
            Expanded(
              child: Text(
                '${S.offlineComplete} '
                '(${state.cachedTileCount} tile-uri, '
                '~${state.cachedSizeMb.toStringAsFixed(1)} MB)',
                style: const TextStyle(fontSize: 13, color: AppColors.green),
              ),
            ),
            TextButton(
              onPressed: controller.deleteCache,
              child: const Text(S.offlineDeleteButton),
            ),
          ],
        );

      case OfflineDownloadStatus.error:
        return Row(
          children: [
            Expanded(
              child: Text(
                state.errorMessage ?? S.offlineError,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: controller.estimateAndDownload,
              child: const Text(S.offlineRetryButton),
            ),
          ],
        );
    }
  }
}
