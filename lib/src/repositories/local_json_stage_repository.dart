// lib/src/repositories/local_json_stage_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/stage_model.dart';
import 'stage_repository.dart';

/// Reads stages from the bundled `assets/data/stages.json` file. This is
/// the offline-first fallback/source used for the MVP; a future
/// `ApiStageRepository` implementing the same [StageRepository] interface
/// can fetch from a hosted endpoint instead (Faza 17) without any UI change.
class LocalJsonStageRepository implements StageRepository {
  List<StageModel>? _cache;

  @override
  Future<List<StageModel>> loadStages() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/stages.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    _cache = [
      for (var i = 0; i < jsonList.length; i++)
        StageModel.fromJson(jsonList[i] as Map<String, dynamic>, fallbackOrder: i),
    ];
    return _cache!;
  }

  @override
  Future<StageModel?> getStageById(String id) async {
    final stages = await loadStages();
    try {
      return stages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
