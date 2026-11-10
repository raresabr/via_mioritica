// lib/src/utils/trail_geo.dart
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Pure geo helpers for the main trail map (kept free of widgets so they can
/// be unit-tested).
class TrailGeo {
  const TrailGeo._();

  /// Romania's extent, used for the initial camera of the main map.
  static final LatLngBounds romania = LatLngBounds(
    const LatLng(43.55, 20.2),
    const LatLng(48.3, 29.75),
  );

  /// The camera centre may not leave this (generous) box around Romania.
  static final LatLngBounds panLimit = LatLngBounds(
    const LatLng(41.5, 17.5),
    const LatLng(50.5, 32.5),
  );

  /// Bounds of [points], or null when empty.
  static LatLngBounds? boundsOf(Iterable<LatLng> points) {
    if (points.isEmpty) return null;
    return LatLngBounds.fromPoints(points.toList());
  }

  /// Bounds covering every non-empty list in [tracks].
  static LatLngBounds? boundsOfAll(Iterable<List<LatLng>> tracks) =>
      boundsOf([for (final t in tracks) ...t]);

  /// Ground resolution in metres per (logical) pixel for 256 px tiles.
  static double metersPerPixel(double latitude, double zoom) =>
      156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

  static const List<int> _niceMeters = [
    10,
    20,
    50,
    100,
    200,
    500,
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  /// Largest "round" distance (in metres) that fits in [maxWidthPx] pixels.
  static int niceScaleMeters({
    required double latitude,
    required double zoom,
    required double maxWidthPx,
  }) {
    final maxMeters = metersPerPixel(latitude, zoom) * maxWidthPx;
    var best = _niceMeters.first;
    for (final m in _niceMeters) {
      if (m <= maxMeters) best = m;
    }
    return best;
  }

  /// "500 m" / "20 km".
  static String formatMeters(int meters) =>
      meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m';
}
