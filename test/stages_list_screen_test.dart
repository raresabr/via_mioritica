import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/models/stage_model.dart';
import 'package:via_mioritica/src/providers/progress_providers.dart';
import 'package:via_mioritica/src/providers/providers.dart';
import 'package:via_mioritica/src/repositories/local_progress_repository.dart';
import 'package:via_mioritica/src/repositories/stage_repository.dart';
import 'package:via_mioritica/src/screens/stages_list_screen.dart';
import 'package:via_mioritica/src/utils/app_strings.dart';

class _FakeStages implements StageRepository {
  _FakeStages(this.stages, {this.fail = false});
  final List<StageModel> stages;
  final bool fail;

  @override
  Future<List<StageModel>> loadStages() async {
    if (fail) throw StateError('boom');
    return stages;
  }

  @override
  Future<StageModel?> getStageById(String id) async =>
      stages.where((s) => s.id == id).firstOrNull;
}

class _MemoryProgress implements LocalProgressRepository {
  final Set<String> done = {};

  @override
  Future<Set<String>> loadCompletedStageIds() async => {...done};

  @override
  Future<void> setStageCompleted(String id, bool completed) async {
    completed ? done.add(id) : done.remove(id);
  }
}

StageModel _stage(String id, String name) => StageModel(
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
);

Widget _app(StageRepository stages, LocalProgressRepository progress) {
  return ProviderScope(
    overrides: [
      stageRepositoryProvider.overrideWithValue(stages),
      localProgressRepositoryProvider.overrideWithValue(progress),
    ],
    child: const MaterialApp(home: StagesListScreen()),
  );
}

void main() {
  testWidgets('renders stages and a 0% progress summary', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeStages([_stage('a', 'Etapa A'), _stage('b', 'Etapa B')]),
        _MemoryProgress(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Etapa A'), findsOneWidget);
    expect(find.text('Etapa B'), findsOneWidget);
    expect(find.text('0/2 ${S.progressSummary}'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('shows persisted progress', (tester) async {
    final progress = _MemoryProgress()..done.add('a');
    await tester.pumpWidget(
      _app(
        _FakeStages([_stage('a', 'Etapa A'), _stage('b', 'Etapa B')]),
        progress,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/2 ${S.progressSummary}'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('shows error state with retry on load failure', (tester) async {
    await tester.pumpWidget(
      _app(_FakeStages(const [], fail: true), _MemoryProgress()),
    );
    await tester.pumpAndSettle();

    expect(find.text(S.errorLoad), findsOneWidget);
    expect(find.text(S.retry), findsOneWidget);
  });
}
