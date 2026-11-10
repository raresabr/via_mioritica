// lib/src/screens/full_trail_map_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/stage_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/map_config.dart';
import '../utils/trail_geo.dart';
import '../widgets/map_scale_bar.dart';
import '../widgets/segment_badge.dart';
import '../widgets/stages_sheet.dart';

/// The main map: all of Romania, with every documented stage (GPX) drawn on
/// it. New stages show up automatically once their GPX is registered in
/// `stages.json`. Distinct from the per-stage [MapScreen] reached from
/// "Ghidul Călătorului", which has offline download + live GPS.
class FullTrailMapScreen extends ConsumerStatefulWidget {
  const FullTrailMapScreen({super.key, this.tileProvider});

  /// Overrides the default (FMTC-cached) tile provider; used by tests.
  final TileProvider? tileProvider;

  /// FMTC store that caches tiles seen on the main map for offline reuse.
  static const storeName = 'main_map';

  @override
  ConsumerState<FullTrailMapScreen> createState() => _FullTrailMapScreenState();
}

class _FullTrailMapScreenState extends ConsumerState<FullTrailMapScreen> {
  static const _stageBadgeMinZoom = 9.0;

  final MapController _mapController = MapController();
  late final TileProvider? _tileProvider = _createTileProvider();
  StreamSubscription<Position>? _positionSub;
  LatLng? _userLocation;

  TileProvider? _createTileProvider() {
    if (widget.tileProvider != null) return widget.tileProvider;
    try {
      unawaited(FMTCStore(FullTrailMapScreen.storeName).manage.create());
      return FMTCTileProvider(
        stores: {
          FullTrailMapScreen.storeName: BrowseStoreStrategy.readUpdateCreate,
        },
        loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      );
    } catch (e) {
      debugPrint('Main map: FMTC unavailable, using network tiles ($e)');
      return null;
    }
  }

  @override
  void dispose() {
    unawaited(_positionSub?.cancel());
    _tileProvider?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesProvider);
    final tracksAsync = ref.watch(allStagesTrackPointsProvider);

    return Scaffold(
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

  Widget _buildMap(List<StageModel> stages, Map<String, List<LatLng>> tracks) {
    final drawn = [
      for (final stage in stages)
        if ((tracks[stage.id] ?? const <LatLng>[]).isNotEmpty) stage,
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: TrailGeo.romania,
              padding: const EdgeInsets.all(8),
            ),
            minZoom: MapConfig.mainMapMinZoom,
            maxZoom: MapConfig.maxZoom.toDouble(),
            cameraConstraint: CameraConstraint.containCenter(
              bounds: TrailGeo.panLimit,
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrl,
              userAgentPackageName: 'ro.viamioritica.app',
              maxZoom: MapConfig.maxZoom.toDouble(),
              tileProvider: _tileProvider,
            ),
            PolylineLayer(
              polylines: [
                for (final stage in drawn)
                  Polyline(
                    points: tracks[stage.id]!,
                    strokeWidth: 4,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    color: AppColors.colorForStageOrder(stage.order),
                  ),
              ],
            ),
            _StageBadges(
              stages: drawn,
              tracks: tracks,
              minZoom: _stageBadgeMinZoom,
            ),
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 24,
                    height: 24,
                    child: const _UserDot(),
                  ),
                ],
              ),
            const MapScaleBar(),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              popupInitialDisplayDuration: Duration.zero,
              attributions: [
                TextSourceAttribution(
                  'MapTiler',
                  onTap: () => _open('https://www.maptiler.com/copyright/'),
                ),
                TextSourceAttribution(
                  'OpenStreetMap',
                  onTap: () => _open('https://www.openstreetmap.org/copyright'),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 24,
          child: FloatingActionButton(
            heroTag: 'main_map_location',
            tooltip: S.fullMapMyLocation,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            onPressed: _goToMyLocation,
            child: const Icon(Icons.navigation),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: FloatingActionButton.extended(
              heroTag: 'main_map_stages',
              backgroundColor: AppColors.textDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.route),
              label: const Text(
                S.fullMapStagesButton,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => _openStages(drawn, tracks),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openStages(
    List<StageModel> stages,
    Map<String, List<LatLng>> tracks,
  ) async {
    final picked = await StagesSheet.show(context, stages);
    if (!mounted) return;
    final bounds = picked == null
        ? TrailGeo.boundsOfAll(tracks.values)
        : TrailGeo.boundsOf(tracks[picked.id] ?? const []);
    if (bounds == null) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 140),
        maxZoom: 14,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await Geolocator.isLocationServiceEnabled()) {
      messenger.showSnackBar(
        const SnackBar(content: Text(S.fullMapLocationUnavailable)),
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(
        const SnackBar(content: Text(S.mapLocationDenied)),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final here = LatLng(pos.latitude, pos.longitude);
    setState(() => _userLocation = here);
    _mapController.move(here, _mapController.camera.zoom.clamp(12.0, 15.0));

    _positionSub ??=
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(distanceFilter: 10),
        ).listen((p) {
          if (!mounted) return;
          setState(() => _userLocation = LatLng(p.latitude, p.longitude));
        });
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// "E1".."E12" badge at each stage's midpoint, shown only when zoomed in
/// enough not to clutter the country-wide view.
class _StageBadges extends StatelessWidget {
  const _StageBadges({
    required this.stages,
    required this.tracks,
    required this.minZoom,
  });

  final List<StageModel> stages;
  final Map<String, List<LatLng>> tracks;
  final double minZoom;

  @override
  Widget build(BuildContext context) {
    if (MapCamera.of(context).zoom < minZoom) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        for (final stage in stages)
          Marker(
            point: tracks[stage.id]![tracks[stage.id]!.length ~/ 2],
            width: 24,
            height: 24,
            child: SegmentBadge(order: stage.order, size: 24),
          ),
      ],
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
