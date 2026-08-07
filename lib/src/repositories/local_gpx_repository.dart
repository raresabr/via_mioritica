// lib/src/repositories/local_gpx_repository.dart
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'gpx_repository.dart';

/// Parses GPX files bundled as assets. GPX tracks are always local/offline
/// (no API-hosted variant is planned — see plan.md "Explicitly out of
/// scope"), but this still implements [GpxRepository] for consistency and
/// testability (e.g. swapping in a fake repository in widget tests).
///
/// Deliberately **not** wrapped in [CacheFirstLoader] (Faza 13): GPX files
/// are bundled forever (never served from a hosted API), so there is no
/// future "real fetch" to simulate — the existing in-memory `_cache` map is
/// sufficient. Parsing itself is fast (<10ms even for large tracks) so a
/// persistent Hive cache would add complexity without a real benefit.
class LocalGpxRepository implements GpxRepository {
  final Map<String, Gpx> _cache = {};

  Future<Gpx> loadGpx(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final xmlStr = await rootBundle.loadString(assetPath);
    final gpx = GpxReader().fromString(xmlStr);
    _cache[assetPath] = gpx;
    return gpx;
  }

  /// Returns all track points as LatLng list from all track segments.
  @override
  Future<List<LatLng>> getTrackPoints(String assetPath) async {
    final gpx = await loadGpx(assetPath);
    final points = <LatLng>[];
    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        for (final pt in seg.trkpts) {
          if (pt.lat != null && pt.lon != null) {
            points.add(LatLng(pt.lat!, pt.lon!));
          }
        }
      }
    }
    return points;
  }
}
