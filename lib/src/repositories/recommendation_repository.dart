// lib/src/repositories/recommendation_repository.dart
import '../models/recommendation_model.dart';

abstract class RecommendationRepository {
  Future<List<RecommendationModel>> loadRecommendations();
}
