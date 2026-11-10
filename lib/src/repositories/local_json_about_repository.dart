// lib/src/repositories/local_json_about_repository.dart
import '../models/about_content_model.dart';
import '../utils/content_config.dart';
import 'json_content_repository.dart';
import 'about_repository.dart';
import '../utils/json_utils.dart';

class LocalJsonAboutRepository implements AboutRepository {
  late final JsonContentRepository<AboutContentModel> _content =
      JsonContentRepository<AboutContentModel>.fromAsset(
        cacheKey: 'about',
        hostedUrl: ContentConfig.hostedUrlFor('about.json'),
        assetPath: 'assets/data/about.json',
        decode: (raw) => AboutContentModel.fromJson(asStringKeyedMap(raw)),
      );

  @override
  Future<AboutContentModel> loadAboutContent() => _content.load();
}
