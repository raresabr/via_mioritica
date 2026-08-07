// lib/src/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/about_content_model.dart';
import '../models/photo_model.dart';
import '../models/recommendation_model.dart';
import '../models/stage_model.dart';
import '../repositories/about_repository.dart';
import '../repositories/gpx_repository.dart';
import '../repositories/local_gpx_repository.dart';
import '../repositories/local_json_about_repository.dart';
import '../repositories/local_json_photo_repository.dart';
import '../repositories/local_json_recommendation_repository.dart';
import '../repositories/local_json_stage_repository.dart';
import '../repositories/photo_repository.dart';
import '../repositories/recommendation_repository.dart';
import '../repositories/stage_repository.dart';

// ── Repositories ──────────────────────────────────────────────────────────────
//
// Providers expose the *interface* type, never the concrete Local* class.
// Swapping in a future `ApiStageRepository` (Faza 17) means changing only
// the line below — no UI/provider-consumer code needs to change.

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return LocalJsonStageRepository();
});

final gpxRepositoryProvider = Provider<GpxRepository>((ref) {
  return LocalGpxRepository();
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  return LocalJsonRecommendationRepository();
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return LocalJsonPhotoRepository();
});

final aboutRepositoryProvider = Provider<AboutRepository>((ref) {
  return LocalJsonAboutRepository();
});

// ── Stages list ───────────────────────────────────────────────────────────────

final stagesProvider = FutureProvider<List<StageModel>>((ref) async {
  return ref.read(stageRepositoryProvider).loadStages();
});

// ── Single stage ──────────────────────────────────────────────────────────────

final stageByIdProvider =
    FutureProvider.family<StageModel?, String>((ref, id) async {
  return ref.read(stageRepositoryProvider).getStageById(id);
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

// ── Recommendations (Faza 8.5 "Recomandări practice") ────────────────────────

final recommendationsProvider = FutureProvider<List<RecommendationModel>>((
  ref,
) async {
  return ref.read(recommendationRepositoryProvider).loadRecommendations();
});

// ── Photos (Faza 8.6 "Album foto") ────────────────────────────────────────────

final photosProvider = FutureProvider<List<PhotoModel>>((ref) async {
  return ref.read(photoRepositoryProvider).loadPhotos();
});

final photosForStageProvider =
    FutureProvider.family<List<PhotoModel>, String>((ref, stageId) async {
  return ref.read(photoRepositoryProvider).loadPhotosForStage(stageId);
});

// ── About content (Faza 8.4 "Despre Noi") ─────────────────────────────────────

final aboutContentProvider = FutureProvider<AboutContentModel>((ref) async {
  return ref.read(aboutRepositoryProvider).loadAboutContent();
});
