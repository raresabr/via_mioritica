// lib/src/repositories/about_repository.dart
import '../models/about_content_model.dart';

abstract class AboutRepository {
  Future<AboutContentModel> loadAboutContent();
}
