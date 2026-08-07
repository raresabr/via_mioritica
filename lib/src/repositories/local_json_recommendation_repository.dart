// lib/src/repositories/local_json_recommendation_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recommendation_model.dart';
import '../utils/cache_first_loader.dart';
import '../utils/content_config.dart';
import 'recommendation_repository.dart';

class LocalJsonRecommendationRepository implements RecommendationRepository {
  List<RecommendationModel>? _cache;

  @override
  Future<List<RecommendationModel>> loadRecommendations() async {
    if (_cache != null) return _cache!;
    final raw = await CacheFirstLoader.load(
      cacheKey: 'recommendations',
      hostedUrl: ContentConfig.hostedUrlFor('recommendations.json'),
      loadFromBundledAsset: () async {
        final jsonStr =
            await rootBundle.loadString('assets/data/recommendations.json');
        return json.decode(jsonStr);
      },
    );
    final jsonList = raw as List<dynamic>;
    _cache = jsonList
        .map((e) => RecommendationModel.fromJson(asStringKeyedMap(e)))
        .toList();
    return _cache!;
  }
}
