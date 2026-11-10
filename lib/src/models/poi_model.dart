// lib/src/models/poi_model.dart

enum PoiType { cazare, popas, obiectiv, recomandare }

PoiType _poiTypeFromString(String s) {
  switch (s) {
    case 'cazare':
      return PoiType.cazare;
    case 'popas':
      return PoiType.popas;
    case 'obiectiv':
      return PoiType.obiectiv;
    default:
      return PoiType.recomandare;
  }
}

String poiTypeLabel(PoiType type) {
  switch (type) {
    case PoiType.cazare:
      return 'Cazare';
    case PoiType.popas:
      return 'Popas';
    case PoiType.obiectiv:
      return 'Obiectiv turistic';
    case PoiType.recomandare:
      return 'Recomandare';
  }
}

class PoiModel {
  final String id;
  final String stageId;
  final PoiType type;
  final String name;
  final double lat;
  final double lon;
  final String description;
  final List<String> photos;

  const PoiModel({
    required this.id,
    required this.stageId,
    required this.type,
    required this.name,
    required this.lat,
    required this.lon,
    required this.description,
    required this.photos,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      type: _poiTypeFromString(json['type'] as String),
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      photos: List<String>.from(json['photos'] as List? ?? []),
    );
  }
}
