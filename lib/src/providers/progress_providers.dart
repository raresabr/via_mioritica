// lib/src/providers/progress_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/hive_progress_repository.dart';
import '../repositories/local_progress_repository.dart';

final localProgressRepositoryProvider = Provider<LocalProgressRepository>((
  ref,
) {
  return HiveProgressRepository();
});

/// Set of completed stage IDs, held in memory and kept in sync with Hive.
/// A plain `Notifier<Set<String>>` (not a `FutureProvider`) so every
/// screen watching it (list badge %, detail-screen checkbox) rebuilds
/// instantly on toggle, without waiting on a re-fetch.
class ProgressController extends Notifier<Set<String>> {
  LocalProgressRepository get _repo =>
      ref.read(localProgressRepositoryProvider);

  @override
  Set<String> build() {
    unawaited(_load());
    return const <String>{};
  }

  Future<void> _load() async {
    final loaded = await _repo.loadCompletedStageIds();
    if (ref.mounted) state = loaded;
  }

  bool isCompleted(String stageId) => state.contains(stageId);

  Future<void> setCompleted(String stageId, bool completed) async {
    await _repo.setStageCompleted(stageId, completed);
    final updated = {...state};
    if (completed) {
      updated.add(stageId);
    } else {
      updated.remove(stageId);
    }
    state = updated;
  }

  Future<void> toggle(String stageId) =>
      setCompleted(stageId, !isCompleted(stageId));
}

final progressProvider = NotifierProvider<ProgressController, Set<String>>(
  ProgressController.new,
);
