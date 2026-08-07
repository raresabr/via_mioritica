// lib/src/widgets/trail_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/map_config.dart';

class TrailMap extends ConsumerStatefulWidget {
  final String gpxAssetPath;
  final LatLng? userLocation;
  final bool compact; // true = small preview card, false = full screen

  const TrailMap({
    super.key,
    required this.gpxAssetPath,
    this.userLocation,
    this.compact = false,
  });

  @override
  ConsumerState<TrailMap> createState() => _TrailMapState();
}

class _TrailMapState extends ConsumerState<TrailMap> {
  final MapController _mapController = MapController();
  bool _followUser = false;

  @override
  Widget build(BuildContext context) {
    final trackAsync = ref.watch(trackPointsProvider(widget.gpxAssetPath));

    return trackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text(S.errorGpx),
          ],
        ),
      ),
      data: (rawPoints) {
        final points = rawPoints.cast<LatLng>();
        final center = points.isNotEmpty
            ? _midPoint(points)
            : const LatLng(46.0, 25.0);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.compact ? 10 : 12,
                minZoom: MapConfig.minZoom.toDouble(),
                maxZoom: MapConfig.maxZoom.toDouble(),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrl,
                  userAgentPackageName: 'ro.viamioritica.app',
                  maxZoom: MapConfig.maxZoom.toDouble(),
                  minZoom: MapConfig.minZoom.toDouble(),
                ),
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 3.5,
                        color: AppColors.green,
                      ),
                    ],
                  ),
                if (widget.userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.userLocation!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Follow-me button (only on full map)
            if (!widget.compact && widget.userLocation != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'follow_me',
                  backgroundColor:
                      _followUser ? AppColors.green : Colors.white,
                  foregroundColor:
                      _followUser ? Colors.white : AppColors.green,
                  onPressed: _toggleFollow,
                  tooltip: S.mapFollowMe,
                  child: const Icon(Icons.my_location),
                ),
              ),
          ],
        );
      },
    );
  }

  void _toggleFollow() {
    setState(() => _followUser = !_followUser);
    if (_followUser && widget.userLocation != null) {
      _mapController.move(widget.userLocation!, _mapController.camera.zoom);
    }
  }

  LatLng _midPoint(List<LatLng> pts) {
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lon);
  }
}

