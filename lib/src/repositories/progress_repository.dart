// lib/src/repositories/progress_repository.dart
import '../models/user_progress_model.dart';

/// Stub interface only — no implementation yet.
///
/// Real progress tracking (checkbox per stage + overall % completion) is
/// built in Faza 15 as a local-only `LocalProgressRepository` (Hive/
/// SharedPreferences, no account required). This interface exists now so
/// that a *future* account-backed sync can implement it later without any
/// UI change, per the "arhitectură fără backend real" decision (V2 plan).
abstract class ProgressRepository {
  Future<UserProgressModel> loadProgress(String userId);
  Future<void> saveProgress(UserProgressModel progress);
}
