import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/providers/offline_map_providers.dart';
import 'package:via_mioritica/src/repositories/offline_map_repository.dart';

class _FakeOfflineRepo extends OfflineMapRepository {
  _FakeOfflineRepo({this.tiles = 0});
  int tiles;
  final calls = <String>[];

  @override
  Future<void> ensureStoreExists(String stageId) async => calls.add('ensure');

  @override
  Future<OfflineStoreStats> getStats(String stageId) async =>
      OfflineStoreStats(tileCount: tiles, sizeKiB: tiles * 18.0);

  @override
  Future<RecoveredRegion?> getFailedRecovery(String stageId) async => null;

  @override
  Future<void> cancelDownload(String stageId) async => calls.add('cancel');

  @override
  Future<void> deleteStore(String stageId) async {
    calls.add('delete');
    tiles = 0;
  }

  @override
  Future<void> pauseDownload(String stageId) async => calls.add('pause');

  @override
  Future<void> resumeDownload(String stageId) async => calls.add('resume');
}

const _args = (stageId: 's1', gpxAssetPath: 'assets/gpx/x.gpx');

ProviderContainer _container(_FakeOfflineRepo repo) {
  final c = ProviderContainer(
    overrides: [offlineMapRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('empty store -> notDownloaded', () async {
    final c = _container(_FakeOfflineRepo());
    c.listen(offlineMapControllerProvider(_args), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(offlineMapControllerProvider(_args)).status,
      OfflineDownloadStatus.notDownloaded,
    );
  });

  test('populated store -> complete with size in MB', () async {
    final c = _container(_FakeOfflineRepo(tiles: 1024));
    c.listen(offlineMapControllerProvider(_args), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final s = c.read(offlineMapControllerProvider(_args));
    expect(s.status, OfflineDownloadStatus.complete);
    expect(s.cachedTileCount, 1024);
    expect(s.cachedSizeMb, closeTo(18, 0.001));
  });

  test('deleteCache wipes the store and returns to notDownloaded', () async {
    final repo = _FakeOfflineRepo(tiles: 10);
    final c = _container(repo);
    c.listen(offlineMapControllerProvider(_args), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    await c.read(offlineMapControllerProvider(_args).notifier).deleteCache();

    expect(repo.calls, contains('delete'));
    expect(
      c.read(offlineMapControllerProvider(_args)).status,
      OfflineDownloadStatus.notDownloaded,
    );
  });

  test('pause and resume flip status', () async {
    final repo = _FakeOfflineRepo();
    final c = _container(repo);
    c.listen(offlineMapControllerProvider(_args), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final ctrl = c.read(offlineMapControllerProvider(_args).notifier);

    await ctrl.pause();
    expect(
      c.read(offlineMapControllerProvider(_args)).status,
      OfflineDownloadStatus.paused,
    );
    await ctrl.resume();
    expect(
      c.read(offlineMapControllerProvider(_args)).status,
      OfflineDownloadStatus.downloading,
    );
  });
}
