// lib/src/screens/full_trail_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/stage_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/map_config.dart';
import '../widgets/segment_badge.dart';

/// Shows the whole trail — all stages/segments at once, each in its own
/// color — with a legend to identify them. Distinct from the per-stage
/// [MapScreen] reached from "Ghidul Călătorului", which shows one segment
/// with offline download + live GPS.
class FullTrailMapScreen extends ConsumerWidget {
  const FullTrailMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);
    final tracksAsync = ref.watch(allStagesTrackPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.fullMapTitle),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: stagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text(S.errorLoad)),
        data: (stages) => tracksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text(S.errorGpx)),
          data: (tracks) => _buildMap(stages, tracks),
        ),
      ),
    );
  }

  Widget _buildMap(
    List<StageModel> stages,
    Map<String, List<dynamic>> tracks,
  ) {
    final allPoints = <LatLng>[
      for (final pts in tracks.values) ...pts.cast<LatLng>(),
    ];
    final center = allPoints.isNotEmpty
        ? LatLng(
            allPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                allPoints.length,
            allPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                allPoints.length,
          )
        : const LatLng(46.0, 25.0);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 8,
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
            PolylineLayer(
              polylines: [
                for (final stage in stages)
                  if ((tracks[stage.id] ?? []).isNotEmpty)
                    Polyline(
                      points: (tracks[stage.id] as List).cast<LatLng>(),
                      strokeWidth: 4,
                      color: AppColors.colorForStageOrder(stage.order),
                    ),
              ],
            ),
            // Faza 19: colorblind-safe shortCode marker at each segment's
            // midpoint — lets a segment be identified directly on the map
            // (not just via the legend below) without relying on color.
            MarkerLayer(
              markers: [
                for (final stage in stages)
                  if ((tracks[stage.id] ?? []).isNotEmpty)
                    Marker(
                      point: _midPoint(
                        (tracks[stage.id] as List).cast<LatLng>(),
                      ),
                      width: 22,
                      height: 22,
                      child: SegmentBadge(order: stage.order, size: 22),
                    ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _Legend(stages: stages),
        ),
      ],
    );
  }

  LatLng _midPoint(List<LatLng> pts) {
    return pts[pts.length ~/ 2];
  }
}

class _Legend extends StatelessWidget {
  final List<StageModel> stages;

  const _Legend({required this.stages});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              S.fullMapLegendTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final stage in stages)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentBadge(order: stage.order, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        stage.name,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
