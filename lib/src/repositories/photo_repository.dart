// lib/src/repositories/photo_repository.dart
import '../models/photo_model.dart';

abstract class PhotoRepository {
  Future<List<PhotoModel>> loadPhotos();

  /// Convenience filter for the per-segment gallery (Faza 8.6).
  Future<List<PhotoModel>> loadPhotosForStage(String stageId);
}
