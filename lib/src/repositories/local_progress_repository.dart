// lib/src/repositories/local_progress_repository.dart

/// Faza 15 — local-only progress tracking (checkbox per stage + overall %
/// completion), no account/login required. This is a **separate**
/// abstraction from the stub `ProgressRepository` in
/// `progress_repository.dart`: that one models a *future* account-backed
/// sync (`userId` + `UserProgressModel`), while this one is scoped to "this
/// device, no user concept at all" — deliberately simpler, since the MVP
/// has no accounts (see plan.md, "Explicitly out of scope for MVP").
///
/// If account-backed sync is ever built, it would likely *read from* a
/// `LocalProgressRepository` implementation to seed/merge the initial
/// upload, rather than one replacing the other.
abstract class LocalProgressRepository {
  /// IDs of stages the user has marked as completed.
  Future<Set<String>> loadCompletedStageIds();

  /// Marks a single stage completed/not-completed and persists immediately.
  Future<void> setStageCompleted(String stageId, bool completed);
}
