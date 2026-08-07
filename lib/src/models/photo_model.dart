// lib/src/models/photo_model.dart

/// A photo shown in the global "Album foto" gallery (Faza 8.6), optionally
/// tied to a stage/segment so the gallery can be filtered per segment.
class PhotoModel {
  final String id;

  /// Null means the photo is trail-wide (not tied to one specific stage).
  final String? stageId;
  final String assetPath;
  final String caption;

  const PhotoModel({
    required this.id,
    this.stageId,
    required this.assetPath,
    this.caption = '',
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      stageId: json['stageId'] as String?,
      assetPath: json['assetPath'] as String,
      caption: json['caption'] as String? ?? '',
    );
  }
}
