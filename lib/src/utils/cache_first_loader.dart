// lib/src/utils/cache_first_loader.dart
import '../services/content_cache_box.dart';

/// Faza 13 — cache-first content loading.
///
/// On a cache MISS (first launch, or cache cleared), this simulates ~1s of
/// network latency before loading from [loadFromSource] (the bundled JSON
/// asset — the offline-first fallback for the MVP), then persists the raw
/// decoded JSON to a Hive box so subsequent app launches/navigations read
/// directly from cache with **zero** delay. This lets the UI's existing
/// loading spinners (every screen already uses `AsyncValue.when(loading: …)`
/// via Riverpod `FutureProvider`s) exercise a realistic "fetching" state
/// even though there's no real backend yet.
///
/// TODO(Faza 17 — hosted JSON): once content is served from a real hosted
/// endpoint, replace [loadFromSource] with an actual `http.get(...)` call
/// and delete [simulatedDelay] entirely. The cache-first read/write logic
/// below does not need to change.
class CacheFirstLoader {
  static const Duration simulatedDelay = Duration(seconds: 1);

  /// Loads raw (decoded JSON) content for [cacheKey]:
  /// 1. Cache HIT → return immediately, no delay (repeat launches, offline).
  /// 2. Cache MISS → simulate network delay, call [loadFromSource], persist
  ///    the result to cache, then return it (first install / cache cleared).
  static Future<dynamic> load({
    required String cacheKey,
    required Future<dynamic> Function() loadFromSource,
  }) async {
    final box = ContentCacheBox.instance;
    final cached = box.get(cacheKey);
    if (cached != null) {
      return cached;
    }
    // TODO(Faza 17): remove this artificial delay when [loadFromSource]
    // becomes a real network call — see class doc above.
    await Future.delayed(simulatedDelay);
    final data = await loadFromSource();
    await box.put(cacheKey, data);
    return data;
  }

  /// Clears a single cached key. Useful for tests, manual cache-busting, or
  /// (later) a "refresh content" action once Faza 17 lands.
  static Future<void> invalidate(String cacheKey) =>
      ContentCacheBox.instance.delete(cacheKey);
}

/// Hive round-trips JSON maps as `Map<dynamic, dynamic>` (not
/// `Map<String, dynamic>`), so every repository must re-cast nested maps
/// before passing them to a model's `fromJson`. Works whether [v] came
/// straight from `dart:convert`'s `json.decode` (already `Map<String,
/// dynamic>`) or from the Hive cache (a `Map` with dynamic keys).
Map<String, dynamic> asStringKeyedMap(dynamic v) =>
    Map<String, dynamic>.from(v as Map);
