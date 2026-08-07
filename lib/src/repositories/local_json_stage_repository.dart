// lib/src/repositories/local_json_stage_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/stage_model.dart';
import '../utils/cache_first_loader.dart';
import 'stage_repository.dart';

/// Reads stages from the bundled `assets/data/stages.json` file, through
/// [CacheFirstLoader] (Faza 13: simulated fetch → Hive cache → cache-first
/// on subsequent reads). This is the offline-first fallback/source used for
/// the MVP; a future `ApiStageRepository` implementing the same
/// [StageRepository] interface can fetch from a hosted endpoint instead
/// (Faza 17) without any UI change.
class LocalJsonStageRepository implements StageRepository {
  List<StageModel>? _cache;

  @override
  Future<List<StageModel>> loadStages() async {
    if (_cache != null) return _cache!;
    final raw = await CacheFirstLoader.load(
      cacheKey: 'stages',
      loadFromSource: () async {
        final jsonStr = await rootBundle.loadString('assets/data/stages.json');
        return json.decode(jsonStr);
      },
    );
    final jsonList = raw as List<dynamic>;
    _cache = [
      for (var i = 0; i < jsonList.length; i++)
        StageModel.fromJson(asStringKeyedMap(jsonList[i]), fallbackOrder: i),
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
