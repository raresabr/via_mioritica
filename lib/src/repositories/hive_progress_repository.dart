// lib/src/repositories/hive_progress_repository.dart
import '../services/progress_box.dart';
import 'local_progress_repository.dart';

/// Hive-backed implementation of [LocalProgressRepository]. Stores a single
/// list of completed stage IDs under one key in `ProgressBox` — a handful
/// of strings, no need for per-stage keys or a typed Hive adapter.
class HiveProgressRepository implements LocalProgressRepository {
  static const _completedStagesKey = 'completed_stage_ids';

  @override
  Future<Set<String>> loadCompletedStageIds() async {
    final raw = ProgressBox.instance.get(_completedStagesKey);
    if (raw is! List) return <String>{};
    return raw.cast<String>().toSet();
  }

  @override
  Future<void> setStageCompleted(String stageId, bool completed) async {
    final current = await loadCompletedStageIds();
    if (completed) {
      current.add(stageId);
    } else {
      current.remove(stageId);
    }
    await ProgressBox.instance.put(_completedStagesKey, current.toList());
  }
}
