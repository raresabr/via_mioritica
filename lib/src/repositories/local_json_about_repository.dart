// lib/src/repositories/local_json_about_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/about_content_model.dart';
import '../utils/cache_first_loader.dart';
import 'about_repository.dart';

class LocalJsonAboutRepository implements AboutRepository {
  AboutContentModel? _cache;

  @override
  Future<AboutContentModel> loadAboutContent() async {
    if (_cache != null) return _cache!;
    final raw = await CacheFirstLoader.load(
      cacheKey: 'about',
      loadFromSource: () async {
        final jsonStr = await rootBundle.loadString('assets/data/about.json');
        return json.decode(jsonStr);
      },
    );
    _cache = AboutContentModel.fromJson(asStringKeyedMap(raw));
    return _cache!;
  }
}
