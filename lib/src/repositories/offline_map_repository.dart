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
      options: TileLayer(
        urlTemplate: MapConfig.tileUrl,
        userAgentPackageName: 'ro.viamioritica.app',
      ),
    );
  }

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
}
