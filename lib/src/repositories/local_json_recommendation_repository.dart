// lib/src/repositories/local_json_recommendation_repository.dart
import '../models/recommendation_model.dart';
import '../utils/content_config.dart';
import 'json_content_repository.dart';
import 'recommendation_repository.dart';
import '../utils/json_utils.dart';

class LocalJsonRecommendationRepository implements RecommendationRepository {
  late final JsonContentRepository<List<RecommendationModel>> _content =
      JsonContentRepository<List<RecommendationModel>>.fromAsset(
        cacheKey: 'recommendations',
        hostedUrl: ContentConfig.hostedUrlFor('recommendations.json'),
        assetPath: 'assets/data/recommendations.json',
        decode: (raw) => (raw as List<dynamic>)
            .map((e) => RecommendationModel.fromJson(asStringKeyedMap(e)))
            .toList(),
      );

  @override
  Future<List<RecommendationModel>> loadRecommendations() => _content.load();
}
