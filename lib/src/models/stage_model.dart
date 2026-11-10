// lib/src/models/stage_model.dart
import '../utils/json_utils.dart';
import 'poi_model.dart';

/// A stage (a.k.a. "segment" in the V2 5-tab navigation/content model) of
/// the Via Mioritica trail.
class StageModel {
  final String id;
  final String name;
  final String gpxFile;
  final double distanceKm;
  final int elevationGainM;
  final int elevationLossM;
  final String difficulty;
  final String durationEstimate;
  final String description;
  final String coverImage;
  final List<PoiModel> pois;

  /// Position of this stage along the trail (0-based). Used to alternate
  /// segment colors deterministically (Faza 9) regardless of JSON/array
  /// order. Falls back to the stage's index in the loaded list if absent
  /// from JSON — see [LocalJsonStageRepository.loadStages].
  final int order;

  const StageModel({
    required this.id,
    required this.name,
    required this.gpxFile,
    required this.distanceKm,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.difficulty,
    required this.durationEstimate,
    required this.description,
    required this.coverImage,
    required this.pois,
    this.order = 0,
  });

  factory StageModel.fromJson(
    Map<String, dynamic> json, {
    int fallbackOrder = 0,
  }) {
    final poisJson = json['pois'] as List? ?? [];
    return StageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      gpxFile: json['gpxFile'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      elevationLossM: (json['elevationLossM'] as num).toInt(),
      difficulty: json['difficulty'] as String? ?? 'Necunoscut',
      durationEstimate: json['durationEstimate'] as String? ?? '–',
      description: json['description'] as String? ?? '',
      coverImage:
          json['coverImage'] as String? ??
          'assets/images/placeholders/stage_placeholder.webp',
      pois: poisJson
          .map((p) => PoiModel.fromJson(asStringKeyedMap(p)))
          .toList(),
      order: (json['order'] as num?)?.toInt() ?? fallbackOrder,
    );
  }
}
