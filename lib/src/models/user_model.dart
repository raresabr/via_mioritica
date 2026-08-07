// lib/src/models/user_model.dart

/// Stub model for a future user account. Not used anywhere yet — Via
/// Mioritica has no login/accounts in the MVP (see plan.md, "Explicitly
/// out of scope for MVP"). Exists only so [ProgressRepository]'s future
/// API-backed implementation has a concrete shape to target without a UI
/// change.
class UserModel {
  final String id;
  final String displayName;

  const UserModel({required this.id, required this.displayName});
}
