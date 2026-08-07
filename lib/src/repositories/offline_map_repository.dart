// lib/src/repositories/offline_map_repository.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../utils/map_config.dart';

/// Approximate average size of a single raster tile (PNG, MapTiler Outdoor),
/// used only to give the user a rough download-size estimate before
/// starting. The real size is reported once the download is in progress.
const double _kAvgTileSizeKiB = 18;

/// Stats about a store: number of cached tiles and their total size.
class OfflineStoreStats {
  final int tileCount;
  final double sizeKiB;

  const OfflineStoreStats({required this.tileCount, required this.sizeKiB});

  bool get isEmpty => tileCount == 0;
}

/// Wraps flutter_map_tile_caching (FMTC) to manage one offline tile store
/// per stage, downloading only the trail corridor (buffer around the GPX
/// track) instead of the whole country.
///
/// NOTE: FMTC is licensed under GPL-v3 — see LICENSE at repo root. Via
/// Mioritica is distributed as open source under the same license to comply.
class OfflineMapRepository {
  /// Store name is derived deterministically from the stage id so the same
  /// store can be referenced from anywhere (TrailMap, download UI, stats)
  /// without passing objects around.
  String storeName(String stageId) => 'stage_$stageId';

  Future<void> ensureStoreExists(String stageId) async {
    await FMTCStore(storeName(stageId)).manage.create();
  }

  /// Builds a downloadable region covering a buffer corridor around the
  /// GPX track (not the whole map), bounded to the offline zoom range.
  DownloadableRegion buildCorridorRegion(List<LatLng> points) {
    final region = LineRegion(points, MapConfig.corridorBufferMeters);
    return region.toDownloadable(
      minZoom: MapConfig.offlineMinZoom,
      maxZoom: MapConfig.offlineMaxZoom,
      options: _tileLayerOptions,
    );
  }

  TileLayer get _tileLayerOptions => TileLayer(
    urlTemplate: MapConfig.tileUrl,
    userAgentPackageName: 'ro.viamioritica.app',
  );

  /// Counts tiles in the region before download, to show a size estimate.
  Future<int> countTiles(String stageId, DownloadableRegion region) {
    return FMTCStore(storeName(stageId)).download.countTiles(region);
  }

  /// Rough download-size estimate in MB, based on average tile size.
  double estimateSizeMb(int tileCount) =>
      (tileCount * _kAvgTileSizeKiB) / 1024;

  /// Starts (or resumes, via FMTC's built-in recovery) the corridor
  /// download for a stage. Returns the two output streams FMTC exposes:
  /// overall progress and per-tile events.
  ({Stream<DownloadProgress> downloadProgress, Stream<TileEvent> tileEvents})
  startDownload(String stageId, DownloadableRegion region) {
    return FMTCStore(storeName(stageId)).download.startForeground(
      region: region,
    );
  }

  Future<void> pauseDownload(String stageId) async {
    FMTCStore(storeName(stageId)).download.pause();
  }

  Future<void> resumeDownload(String stageId) async {
    FMTCStore(storeName(stageId)).download.resume();
  }

  Future<void> cancelDownload(String stageId) {
    return FMTCStore(storeName(stageId)).download.cancel();
  }

  Future<bool> storeReady(String stageId) {
    return FMTCStore(storeName(stageId)).manage.ready;
  }

  Future<OfflineStoreStats> getStats(String stageId) async {
    final ready = await storeReady(stageId);
    if (!ready) return const OfflineStoreStats(tileCount: 0, sizeKiB: 0);
    final store = FMTCStore(storeName(stageId));
    final tileCount = await store.stats.length;
    final sizeKiB = await store.stats.size;
    return OfflineStoreStats(tileCount: tileCount, sizeKiB: sizeKiB);
  }

  Future<void> deleteStore(String stageId) async {
    final ready = await storeReady(stageId);
    if (!ready) return;
    await FMTCStore(storeName(stageId)).manage.delete();
  }

  /// Faza 21 — resumable downloads across app restarts.
  ///
  /// FMTC records a "recovery" entry (store name + progress) whenever a
  /// download starts, and only clears it if the download finishes
  /// normally. If the app is killed/crashes mid-download, that entry
  /// survives — this looks it up for [stageId]'s store, filtered to only
  /// "failed" ones (i.e. no longer actually running in memory, see
  /// `RootRecovery` docs), so an interrupted download can be detected and
  /// resumed later without redownloading tiles it already fetched.
  Future<RecoveredRegion?> getFailedRecovery(String stageId) async {
    final all = await FMTCRoot.recovery.recoverableRegions;
    for (final entry in all) {
      if (entry.isFailed && entry.region.storeName == storeName(stageId)) {
        return entry.region;
      }
    }
    return null;
  }

  /// Converts a recovered region back into a [DownloadableRegion] whose
  /// `start` is set to skip tiles already downloaded before the
  /// interruption — resuming, not restarting, the download.
  DownloadableRegion regionFromRecovery(RecoveredRegion recovered) =>
      recovered.toDownloadable(_tileLayerOptions);

  /// Discards a stale recovery entry (e.g. after the resumed download
  /// finishes, or the user cancels/deletes the store instead of resuming).
  Future<void> cancelRecovery(int recoveryId) =>
      FMTCRoot.recovery.cancel(recoveryId);
}
