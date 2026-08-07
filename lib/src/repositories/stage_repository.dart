// lib/src/repositories/stage_repository.dart
import '../models/stage_model.dart';

/// Abstract data-access contract for stages/segments. UI and providers
/// depend on this interface, never on a concrete implementation, so a
/// future `ApiStageRepository` can replace [LocalJsonStageRepository]
/// without touching any screen or widget.
abstract class StageRepository {
  Future<List<StageModel>> loadStages();
  Future<StageModel?> getStageById(String id);
}
