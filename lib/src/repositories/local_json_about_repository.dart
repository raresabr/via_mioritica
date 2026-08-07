// lib/src/repositories/local_json_about_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/about_content_model.dart';
import 'about_repository.dart';

class LocalJsonAboutRepository implements AboutRepository {
  AboutContentModel? _cache;

  @override
  Future<AboutContentModel> loadAboutContent() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/about.json');
    final Map<String, dynamic> jsonMap =
        json.decode(jsonStr) as Map<String, dynamic>;
    _cache = AboutContentModel.fromJson(jsonMap);
    return _cache!;
  }
}
