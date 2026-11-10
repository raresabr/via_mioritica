// lib/src/services/progress_box.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Separate Hive box for local progress tracking (Faza 15) — kept apart
/// from `ContentCacheBox` (Faza 13) on purpose: that box is a *disposable*
/// content cache (safe to clear/rebuild any time, re-populated from
/// network/bundled JSON), while this one holds user data (which stages the
/// user has actually hiked) that must never be wiped as a side effect of
/// clearing cached content.
class ProgressBox {
  static const String boxName = 'user_progress';
  static Box? _box;

  /// Must be called once before any repository reads/writes progress
  /// (done in `main.dart`, alongside `ContentCacheBox.init()`).
  static Future<void> init({String? path}) async {
    if (_box != null) return;
    // `Hive.initFlutter()` is idempotent — already called by
    // `ContentCacheBox.init()`, but calling it again here keeps this class
    // self-contained/safe to use standalone (e.g. in tests).
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(boxName);
  }

  static Box get instance {
    final box = _box;
    if (box == null) {
      throw StateError(
        'ProgressBox.init() must be awaited before use (see main.dart).',
      );
    }
    return box;
  }

  /// Closes and forgets the box. Test-only.
  @visibleForTesting
  static Future<void> resetForTest() async {
    await _box?.close();
    _box = null;
  }
}
