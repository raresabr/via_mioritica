// lib/src/services/content_cache_box.dart
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Single Hive box shared by all local content repositories for cache-first
/// loading (Faza 13). Stores raw decoded JSON (Map/List of primitives), not
/// typed Dart model classes — repositories always map JSON → model after
/// reading, whether the raw data came from a fresh "fetch" or the cache —
/// so no Hive `TypeAdapter` codegen is needed for `StageModel` etc.
class ContentCacheBox {
  static const String boxName = 'content_cache';
  static Box<dynamic>? _box;

  /// Must be called once before any repository reads/writes the cache
  /// (done in `main.dart`, alongside the FMTC init).
  static Future<void> init({String? path}) async {
    if (_box != null) return;
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox<dynamic>(boxName);
  }

  static Box<dynamic> get instance {
    final box = _box;
    if (box == null) {
      throw StateError(
        'ContentCacheBox.init() must be awaited before use (see main.dart).',
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
