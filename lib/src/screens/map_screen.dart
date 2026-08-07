// lib/src/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    _positionSub = Geolocator.getPositionStream(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          TrailMap(
            gpxAssetPath: widget.stage.gpxFile,
            stageId: widget.stage.id,
            userLocation: _userLocation,
            compact: false,
          ),
          if (_locationDenied)
            Positioned(
              bottom: 16,
              left: 16,
              right: 72,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off,
                          color: AppColors.brown, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          S.mapLocationDenied,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

