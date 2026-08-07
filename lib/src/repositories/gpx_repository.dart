// lib/src/repositories/gpx_repository.dart
import 'package:latlong2/latlong.dart';

/// Abstract data-access contract for GPX track data. UI/providers depend on
/// this interface, not on a concrete implementation.
abstract class GpxRepository {
  Future<List<LatLng>> getTrackPoints(String assetPath);
}
