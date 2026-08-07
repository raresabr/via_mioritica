// lib/src/services/content_cache_box.dart
import 'package:hive_flutter/hive_flutter.dart';

/// Single Hive box shared by all local content repositories for cache-first
/// loading (Faza 13). Stores raw decoded JSON (Map/List of primitives), not
/// typed Dart model classes — repositories always map JSON → model after
/// reading, whether the raw data came from a fresh "fetch" or the cache —
/// so no Hive `TypeAdapter` codegen is needed for `StageModel` etc.
class ContentCacheBox {
  static const String boxName = 'content_cache';
  static Box? _box;

  /// Must be called once before any repository reads/writes the cache
  /// (done in `main.dart`, alongside the FMTC init).
  static Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  static Box get instance {
    final box = _box;
    if (box == null) {
      throw StateError(
        'ContentCacheBox.init() must be awaited before use (see main.dart).',
      );
    }
    return box;
  }
}
