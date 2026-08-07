// lib/src/models/recommendation_model.dart

/// Category of a practical recommendation, used to group entries in the
/// "Recomandări practice" tab and to pick an icon in the UI.
enum RecommendationCategory { echipament, siguranta, apa, vreme, general }

RecommendationCategory _categoryFromString(String s) {
  switch (s) {
    case 'echipament':
      return RecommendationCategory.echipament;
    case 'siguranta':
      return RecommendationCategory.siguranta;
    case 'apa':
      return RecommendationCategory.apa;
    case 'vreme':
      return RecommendationCategory.vreme;
    default:
      return RecommendationCategory.general;
  }
}

String recommendationCategoryLabel(RecommendationCategory category) {
  switch (category) {
    case RecommendationCategory.echipament:
      return 'Echipament';
    case RecommendationCategory.siguranta:
      return 'Siguranță';
    case RecommendationCategory.apa:
      return 'Apă';
    case RecommendationCategory.vreme:
      return 'Vreme';
    case RecommendationCategory.general:
      return 'General';
  }
}

/// A general (trail-wide, not stage-specific) practical recommendation —
/// modeled as if it came from an API from day one (Faza 7 API-readiness),
/// even though it is currently read from a bundled JSON asset.
class RecommendationModel {
  final String id;
  final RecommendationCategory category;
  final String title;
  final String body;

  const RecommendationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] as String,
      category: _categoryFromString(json['category'] as String? ?? 'general'),
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
    );
  }
}
