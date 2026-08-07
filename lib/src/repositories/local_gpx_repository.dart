// lib/src/repositories/local_gpx_repository.dart
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'gpx_repository.dart';

/// Parses GPX files bundled as assets. GPX tracks are always local/offline
/// (no API-hosted variant is planned — see plan.md "Explicitly out of
/// scope"), but this still implements [GpxRepository] for consistency and
/// testability (e.g. swapping in a fake repository in widget tests).
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

  /// Returns elevation data as list of (distance_km, elevation_m) pairs.
  ///
  /// Downsamples to [maxPoints] and applies a moving-average smooth so that
  /// the chart renders correctly regardless of how many track-points the GPX
  /// file contains (works for 150-pt hikes and 100 k-pt bike rides alike).
  @override
  Future<List<(double, double)>> getElevationProfile(
    String assetPath, {
    int maxPoints = 400,
  }) async {
    final gpx = await loadGpx(assetPath);
    final raw = <(double, double)>[];
    const distance = Distance();
    double cumulativeKm = 0;
    LatLng? prev;

    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        for (final pt in seg.trkpts) {
          if (pt.lat == null || pt.lon == null) continue;
          final current = LatLng(pt.lat!, pt.lon!);
          if (prev != null) {
            cumulativeKm += distance.as(LengthUnit.Kilometer, prev, current);
          }
          raw.add((cumulativeKm, pt.ele ?? 0));
          prev = current;
        }
      }
    }

    if (raw.isEmpty) return raw;

    // ── Downsample ────────────────────────────────────────────────────────────
    // Pick evenly spaced indices so the output has at most [maxPoints] entries.
    final stride = (raw.length / maxPoints).ceil().clamp(1, raw.length);
    final sampled = <(double, double)>[];
    for (var i = 0; i < raw.length; i += stride) {
      sampled.add(raw[i]);
    }
    // Always include the final point so distance is accurate.
    if (sampled.last != raw.last) sampled.add(raw.last);

    // ── Moving-average smooth (window scales with stride) ─────────────────────
    // Larger stride means the remaining points are further apart and GPS
    // elevation noise is more visible → use a proportionally wider window.
    final half = (stride ~/ 2).clamp(1, 5);
    final smoothed = <(double, double)>[];
    for (var i = 0; i < sampled.length; i++) {
      final lo = (i - half).clamp(0, sampled.length - 1);
      final hi = (i + half).clamp(0, sampled.length - 1);
      double sumEle = 0;
      for (var j = lo; j <= hi; j++) {
        sumEle += sampled[j].$2;
      }
      smoothed.add((sampled[i].$1, sumEle / (hi - lo + 1)));
    }

    return smoothed;
  }
}
