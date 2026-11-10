// lib/src/repositories/local_json_stage_repository.dart
import '../models/stage_model.dart';
import '../utils/content_config.dart';
import 'json_content_repository.dart';
import 'stage_repository.dart';
import '../utils/json_utils.dart';

class LocalJsonStageRepository implements StageRepository {
  late final JsonContentRepository<List<StageModel>> _content =
      JsonContentRepository<List<StageModel>>.fromAsset(
        cacheKey: 'stages',
        hostedUrl: ContentConfig.hostedUrlFor('stages.json'),
        assetPath: 'assets/data/stages.json',
        decode: (raw) {
          final jsonList = raw as List<dynamic>;
          return [
            for (var i = 0; i < jsonList.length; i++)
              StageModel.fromJson(
                asStringKeyedMap(jsonList[i]),
                fallbackOrder: i,
              ),
          ];
        },
      );

  @override
  Future<List<StageModel>> loadStages() => _content.load();

  @override
  Future<StageModel?> getStageById(String id) async {
    final stages = await loadStages();
    for (final stage in stages) {
      if (stage.id == id) return stage;
    }
    return null;
  }
}
