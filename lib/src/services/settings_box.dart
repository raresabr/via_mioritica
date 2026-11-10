// lib/src/services/settings_box.dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Small Hive box for one-off local app-state flags (Faza 20: has the user
/// already seen the offline-download onboarding tip?). Deliberately
/// **separate** from `ProgressBox` (Faza 15, actual hiking progress data —
/// never mixed with disposable UI-state flags) and from `ContentCacheBox`
/// (Faza 13, disposable content cache — a settings flag must survive a
/// content cache clear).
class SettingsBox {
  static const String boxName = 'app_settings';
  static Box<dynamic>? _box;

  static const String keyHasSeenOfflineOnboarding =
      'has_seen_offline_onboarding';

  /// Must be called once before any read/write (done in `main.dart`,
  /// alongside `ContentCacheBox.init()`/`ProgressBox.init()`).
  static Future<void> init() async {
    if (_box != null) return;
    // `Hive.initFlutter()` is idempotent — already called elsewhere, but
    // repeating it here keeps this class self-contained/safe standalone.
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(boxName);
  }

  static Box<dynamic> get instance {
    final box = _box;
    if (box == null) {
      throw StateError(
        'SettingsBox.init() must be awaited before use (see main.dart).',
      );
    }
    return box;
  }

  static bool get hasSeenOfflineOnboarding =>
      instance.get(keyHasSeenOfflineOnboarding, defaultValue: false) as bool;

  static Future<void> markOfflineOnboardingSeen() =>
      instance.put(keyHasSeenOfflineOnboarding, true);
}
