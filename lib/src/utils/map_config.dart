// lib/src/utils/map_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConfig {
  /// MapTiler Outdoor tile URL template.
  /// API key loaded from .env (MAPTILER_KEY) – never hardcode in source.
  static String get tileUrl {
    final key = dotenv.maybeGet('MAPTILER_KEY') ?? '';
    return 'https://api.maptiler.com/maps/outdoor/{z}/{x}/{y}.png?key=$key';
  }

  static const String tileAttribution =
      '© <a href="https://www.maptiler.com/copyright/">MapTiler</a> '
      '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>';

  static const int minZoom = 8;
  static const int maxZoom = 17;

  /// Zoom levels to cache for offline use (corridor download).
  static const int offlineMinZoom = 10;
  static const int offlineMaxZoom = 16;

  /// Buffer in degrees (~3 km) around GPX track for corridor tile download.
  /// Kept for backwards reference; use [corridorBufferMeters] for FMTC's
  /// LineRegion (which expects a radius in meters, not degrees).
  static const double corridorBufferDeg = 0.03;

  /// Corridor half-width in meters around the GPX track, used by FMTC's
  /// LineRegion to bound the offline tile download to the trail corridor
  /// instead of the whole country.
  static const double corridorBufferMeters = 3000;
}
