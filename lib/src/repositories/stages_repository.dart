// lib/src/repositories/stages_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/stage_model.dart';

class StagesRepository {
  List<StageModel>? _cache;

  Future<List<StageModel>> loadStages() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/stages.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    _cache =
        jsonList
            .map((e) => StageModel.fromJson(e as Map<String, dynamic>))
            .toList();
    return _cache!;
  }

  Future<StageModel?> getStageById(String id) async {
    final stages = await loadStages();
    try {
      return stages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

