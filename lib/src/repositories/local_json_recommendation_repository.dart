// lib/src/repositories/local_json_recommendation_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recommendation_model.dart';
import 'recommendation_repository.dart';

class LocalJsonRecommendationRepository implements RecommendationRepository {
  List<RecommendationModel>? _cache;

  @override
  Future<List<RecommendationModel>> loadRecommendations() async {
    if (_cache != null) return _cache!;
    final jsonStr =
        await rootBundle.loadString('assets/data/recommendations.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    _cache = jsonList
        .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
