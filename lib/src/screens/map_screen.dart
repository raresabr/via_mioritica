// lib/src/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../widgets/design.dart';
import '../widgets/segment_badge.dart';
import '../widgets/trail_map.dart';

class MapScreen extends ConsumerStatefulWidget {
  final StageModel stage;

  const MapScreen({super.key, required this.stage});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionSub;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationDenied = true);
      return;
    }

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // update every 10 metres
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(pos.latitude, pos.longitude);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          TrailMap(
            gpxAssetPath: widget.stage.gpxFile,
            stageId: widget.stage.id,
            userLocation: _userLocation,
            compact: false,
            segmentColor: AppColors.colorForStageOrder(widget.stage.order),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassContainer(
                    radius: 30,
                    blur: 20,
                    dark: true,
                    fillOpacity: 0.5,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                    child: Row(
                      children: [
                        SegmentBadge(order: widget.stage.order, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_locationDenied)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              left: 16,
              right: 84,
              child: GlassContainer(
                radius: 22,
                dark: true,
                fillOpacity: 0.55,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      color: AppColors.sun,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        S.mapLocationDenied,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
