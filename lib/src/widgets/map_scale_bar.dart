// lib/src/widgets/map_scale_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../utils/trail_geo.dart';

/// Metric scale bar, reads the zoom/latitude from the surrounding
/// [FlutterMap] and rebuilds as the camera moves.
class MapScaleBar extends StatelessWidget {
  const MapScaleBar({super.key, this.maxWidth = 110});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final meters = TrailGeo.niceScaleMeters(
      latitude: camera.center.latitude,
      zoom: camera.zoom,
      maxWidthPx: maxWidth,
    );
    final width =
        meters / TrailGeo.metersPerPixel(camera.center.latitude, camera.zoom);

    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TrailGeo.formatMeters(meters),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    key: const Key('scaleBarLine'),
                    width: width,
                    height: 5,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(width: 2),
                        right: BorderSide(width: 2),
                        bottom: BorderSide(width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
