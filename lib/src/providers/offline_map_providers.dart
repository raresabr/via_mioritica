// lib/src/providers/offline_map_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/offline_map_repository.dart';
import 'providers.dart';

final offlineMapRepositoryProvider = Provider<OfflineMapRepository>((ref) {
  return OfflineMapRepository();
});

enum OfflineDownloadStatus {
  /// Stats not loaded yet.
  loading,

  /// No tiles cached for this stage.
  notDownloaded,

  /// Estimating tile count/size before starting the actual download.
  estimating,

  /// Download in progress.
  downloading,

  /// Download paused by the user (resumable within the same app session).
  paused,

  /// All tiles for the corridor are cached.
  complete,

  /// Something went wrong (network error, FMTC error, etc).
  error,
}

class OfflineDownloadState {
  final OfflineDownloadStatus status;
  final int cachedTileCount;
  final double cachedSizeMb;
  final int? estimatedTileCount;
  final double? progressPercent; // 0-100, only meaningful while downloading
  final String? errorMessage;

  const OfflineDownloadState({
    required this.status,
    this.cachedTileCount = 0,
    this.cachedSizeMb = 0,
    this.estimatedTileCount,
    this.progressPercent,
    this.errorMessage,
  });

  OfflineDownloadState copyWith({
    OfflineDownloadStatus? status,
    int? cachedTileCount,
    double? cachedSizeMb,
    int? estimatedTileCount,
    double? progressPercent,
    String? errorMessage,
  }) {
    return OfflineDownloadState(
      status: status ?? this.status,
      cachedTileCount: cachedTileCount ?? this.cachedTileCount,
      cachedSizeMb: cachedSizeMb ?? this.cachedSizeMb,
      estimatedTileCount: estimatedTileCount ?? this.estimatedTileCount,
      progressPercent: progressPercent,
      errorMessage: errorMessage,
    );
  }
}

/// Manages the offline-download lifecycle (estimate -> download -> pause/
/// resume/cancel -> delete) for a single stage's corridor tile store.
class OfflineMapController extends StateNotifier<OfflineDownloadState> {
  final OfflineMapRepository _repo;
  final String stageId;
  final String gpxAssetPath;
  final Ref _ref;
  StreamSubscription? _progressSub;

  OfflineMapController(this._repo, this._ref, this.stageId, this.gpxAssetPath)
    : super(const OfflineDownloadState(status: OfflineDownloadStatus.loading)) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    await _repo.ensureStoreExists(stageId);
    final stats = await _repo.getStats(stageId);
    state = state.copyWith(
      status: stats.isEmpty
          ? OfflineDownloadStatus.notDownloaded
          : OfflineDownloadStatus.complete,
      cachedTileCount: stats.tileCount,
      cachedSizeMb: stats.sizeKiB / 1024,
    );
  }

  Future<void> estimateAndDownload() async {
    state = state.copyWith(status: OfflineDownloadStatus.estimating);
    try {
      final points = await _ref.read(
        trackPointsProvider(gpxAssetPath).future,
      );
      final region = _repo.buildCorridorRegion(points.cast());
      final tileCount = await _repo.countTiles(stageId, region);
      state = state.copyWith(
        status: OfflineDownloadStatus.downloading,
        estimatedTileCount: tileCount,
        progressPercent: 0,
      );

      final (:downloadProgress, :tileEvents) = _repo.startDownload(
        stageId,
        region,
      );
      unawaited(tileEvents.drain());
      _progressSub = downloadProgress.listen(
        (progress) {
          state = state.copyWith(
            progressPercent: progress.percentageProgress,
          );
        },
        onDone: () async {
          await _loadStats();
        },
        onError: (e) {
          state = state.copyWith(
            status: OfflineDownloadStatus.error,
            errorMessage: e.toString(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: OfflineDownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> pause() async {
    await _repo.pauseDownload(stageId);
    state = state.copyWith(status: OfflineDownloadStatus.paused);
  }

  Future<void> resume() async {
    await _repo.resumeDownload(stageId);
    state = state.copyWith(status: OfflineDownloadStatus.downloading);
  }

  Future<void> cancelAndDelete() async {
    await _progressSub?.cancel();
    await _repo.cancelDownload(stageId);
    await _repo.deleteStore(stageId);
    await _loadStats();
  }

  Future<void> deleteCache() async {
    await _repo.deleteStore(stageId);
    await _loadStats();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}

final offlineMapControllerProvider = StateNotifierProvider.family<
  OfflineMapController,
  OfflineDownloadState,
  ({String stageId, String gpxAssetPath})
>((ref, args) {
  final repo = ref.watch(offlineMapRepositoryProvider);
  return OfflineMapController(repo, ref, args.stageId, args.gpxAssetPath);
});
