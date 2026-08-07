// lib/src/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage_model.dart';
import '../repositories/stages_repository.dart';
import '../repositories/gpx_repository.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final stagesRepositoryProvider = Provider<StagesRepository>((ref) {
  return StagesRepository();
});

final gpxRepositoryProvider = Provider<GpxRepository>((ref) {
  return GpxRepository();
});

// ── Stages list ───────────────────────────────────────────────────────────────

final stagesProvider = FutureProvider<List<StageModel>>((ref) async {
  return ref.read(stagesRepositoryProvider).loadStages();
});

// ── Single stage ──────────────────────────────────────────────────────────────

final stageByIdProvider =
    FutureProvider.family<StageModel?, String>((ref, id) async {
  return ref.read(stagesRepositoryProvider).getStageById(id);
});

// ── GPX track points per stage ────────────────────────────────────────────────

final trackPointsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, gpxAssetPath) async {
  return ref.read(gpxRepositoryProvider).getTrackPoints(gpxAssetPath);
});

// ── Elevation profile per stage ───────────────────────────────────────────────

final elevationProfileProvider =
    FutureProvider.family<List<(double, double)>, String>(
        (ref, gpxAssetPath) async {
  return ref.read(gpxRepositoryProvider).getElevationProfile(gpxAssetPath);
});

