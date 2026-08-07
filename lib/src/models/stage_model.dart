// lib/src/models/stage_model.dart
import 'poi_model.dart';

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
  });

  factory StageModel.fromJson(Map<String, dynamic> json) {
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
          .map((p) => PoiModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

