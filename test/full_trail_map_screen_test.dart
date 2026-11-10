import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:via_mioritica/src/models/stage_model.dart';
import 'package:via_mioritica/src/providers/providers.dart';
import 'package:via_mioritica/src/repositories/gpx_repository.dart';
import 'package:via_mioritica/src/repositories/stage_repository.dart';
import 'package:via_mioritica/src/screens/full_trail_map_screen.dart';
import 'package:via_mioritica/src/utils/app_strings.dart';

class _FakeStages implements StageRepository {
  _FakeStages(this.stages);
  final List<StageModel> stages;

  @override
  Future<List<StageModel>> loadStages() async => stages;

  @override
  Future<StageModel?> getStageById(String id) async =>
      stages.where((s) => s.id == id).firstOrNull;
}

class _FakeGpx implements GpxRepository {
  @override
  Future<List<LatLng>> getTrackPoints(String assetPath) async => const [
    LatLng(46.0, 22.0),
    LatLng(46.1, 22.1),
    LatLng(46.2, 22.2),
  ];
}

class _BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

final _transparentPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x60,
  0x60,
  0x60,
  0x60,
  0x00,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0xA5,
  0xF6,
  0x45,
  0x40,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

StageModel _stage(String id, String name, int order) => StageModel(
  id: id,
  name: name,
  gpxFile: 'assets/gpx/$id.gpx',
  distanceKm: 10,
  elevationGainM: 100,
  elevationLossM: 100,
  difficulty: 'Mediu',
  durationEstimate: '3 ore',
  description: '',
  coverImage: '',
  pois: const [],
  order: order,
);

Widget _app(List<StageModel> stages) => ProviderScope(
  overrides: [
    stageRepositoryProvider.overrideWithValue(_FakeStages(stages)),
    gpxRepositoryProvider.overrideWithValue(_FakeGpx()),
  ],
  child: MaterialApp(
    home: FullTrailMapScreen(tileProvider: _BlankTileProvider()),
  ),
);

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'MAPTILER_KEY=test'));

  testWidgets('shows map, scale bar, location and stages buttons', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_stage('a', 'Brad – Baia', 0)]));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(find.byKey(const Key('scaleBarLine')), findsOneWidget);
    expect(find.text(S.fullMapStagesButton), findsOneWidget);
    expect(find.byTooltip(S.fullMapMyLocation), findsOneWidget);
  });

  testWidgets('stages sheet lists stages and selecting one closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([_stage('a', 'Brad – Baia', 0), _stage('b', 'Baia – Grohot', 1)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.fullMapStagesButton));
    await tester.pumpAndSettle();
    expect(find.text('Brad – Baia'), findsOneWidget);
    expect(find.text('Baia – Grohot'), findsOneWidget);
    expect(find.textContaining('20.0 km'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stagesSheet_b')));
    await tester.pumpAndSettle();
    expect(find.text('Baia – Grohot'), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('"whole trail" entry closes the sheet', (tester) async {
    await tester.pumpWidget(_app([_stage('a', 'Brad – Baia', 0)]));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.fullMapStagesButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stagesSheetAll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stagesSheetAll')), findsNothing);
  });
}
