// lib/src/repositories/local_json_photo_repository.dart
import '../models/photo_model.dart';
import '../utils/content_config.dart';
import '../utils/json_utils.dart';
import 'json_content_repository.dart';
import 'photo_repository.dart';

class LocalJsonPhotoRepository implements PhotoRepository {
  late final JsonContentRepository<List<PhotoModel>> _content =
      JsonContentRepository<List<PhotoModel>>.fromAsset(
        cacheKey: 'photos',
        hostedUrl: ContentConfig.hostedUrlFor('photos.json'),
        assetPath: 'assets/data/photos.json',
        decode: (raw) => (raw as List<dynamic>)
            .map((e) => PhotoModel.fromJson(asStringKeyedMap(e)))
            .toList(),
      );

  @override
  Future<List<PhotoModel>> loadPhotos() => _content.load();

  @override
  Future<List<PhotoModel>> loadPhotosForStage(String stageId) async {
    final all = await loadPhotos();
    return all.where((photo) => photo.stageId == stageId).toList();
  }
}
