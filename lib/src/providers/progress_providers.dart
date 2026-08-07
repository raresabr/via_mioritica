// lib/src/providers/progress_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/hive_progress_repository.dart';
import '../repositories/local_progress_repository.dart';

final localProgressRepositoryProvider = Provider<LocalProgressRepository>((
  ref,
) {
  return HiveProgressRepository();
});

/// Set of completed stage IDs, held in memory and kept in sync with Hive.
/// A plain `StateNotifier<Set<String>>` (not a `FutureProvider`) so every
/// screen watching it (list badge %, detail-screen checkbox) rebuilds
/// instantly on toggle, without waiting on a re-fetch.
class ProgressController extends StateNotifier<Set<String>> {
  final LocalProgressRepository _repo;

  ProgressController(this._repo) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadCompletedStageIds();
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

final progressProvider =
    StateNotifierProvider<ProgressController, Set<String>>((ref) {
  return ProgressController(ref.watch(localProgressRepositoryProvider));
});
