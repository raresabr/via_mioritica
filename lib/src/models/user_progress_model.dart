// lib/src/models/user_progress_model.dart

/// Stub model for a future account-backed progress sync. The real,
/// account-free local implementation (checkbox per stage + overall %) is
/// built in Faza 15 as `SegmentProgress` — this model exists only to give
/// [ProgressRepository]'s future API-backed variant a concrete shape.
class UserProgressModel {
  final String userId;
  final List<String> completedStageIds;

  const UserProgressModel({
    required this.userId,
    required this.completedStageIds,
  });
}
