// lib/src/repositories/local_json_photo_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/photo_model.dart';
import 'photo_repository.dart';

class LocalJsonPhotoRepository implements PhotoRepository {
  List<PhotoModel>? _cache;

  @override
  Future<List<PhotoModel>> loadPhotos() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/photos.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    _cache = jsonList
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  @override
  Future<List<PhotoModel>> loadPhotosForStage(String stageId) async {
    final all = await loadPhotos();
    return all.where((p) => p.stageId == stageId).toList();
  }
}
