// lib/src/utils/cache_first_loader.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/content_cache_box.dart';
import 'content_config.dart';

export 'json_utils.dart' show asStringKeyedMap;

/// Faza 13/17 — cache-first content loading with a real hosted JSON source.
///
/// Read path for [load]:
/// 1. **Cache HIT** → return the cached data **immediately** (no network
///    wait), then kick off a fire-and-forget background revalidation
///    against the hosted URL (conditional GET via `If-None-Match`/ETag). If
///    the hosted content changed, the cache is updated silently — the
///    *next* cold start of the app will pick up the new content. This is
///    what makes "update content without a new app release" possible
///    (Faza 17) while keeping every screen navigation instant and
///    network-free (only the first read per app session touches this
///    class at all — see each repository's own in-memory `_cache`).
/// 2. **Cache MISS** (first install, or cache cleared) → try a real HTTP
///    GET against the hosted JSON first; on any failure (offline, DNS,
///    timeout, non-200) fall back to the bundled JSON asset
///    ([loadFromBundledAsset]) — the offline-first guarantee for a clean
///    install with no connectivity.
///
/// Change detection uses the HTTP `ETag` response header (GitHub's raw CDN
/// sets one per file) rather than a hand-maintained "version" field inside
/// each JSON file — it updates itself automatically whenever content
/// actually changes, with no risk of a content editor forgetting to bump a
/// version number.
class CacheFirstLoader {
  /// Loads raw (decoded JSON) content for [cacheKey], from [hostedUrl] with
  /// [loadFromBundledAsset] as the offline-first fallback.
  static Future<dynamic> load({
    required String cacheKey,
    required String hostedUrl,
    required Future<dynamic> Function() loadFromBundledAsset,
    void Function(dynamic data)? validate,
  }) async {
    final box = ContentCacheBox.instance;
    final entry = box.get(cacheKey);

    if (entry is Map &&
        entry.containsKey('data') &&
        _isValid(entry['data'], validate)) {
      // Cache-first: return instantly, revalidate quietly in the background.
      unawaited(
        _revalidateInBackground(
          cacheKey,
          hostedUrl,
          entry['etag'] as String?,
          validate,
        ),
      );
      return entry['data'];
    }
    if (entry != null) {
      // Corrupt/incompatible cache entry: drop it and start from scratch.
      await box.delete(cacheKey);
    }

    // Cache MISS: try the real hosted fetch first.
    try {
      final response = await http
          .get(Uri.parse(hostedUrl))
          .timeout(ContentConfig.networkTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        validate?.call(data);
        await _store(cacheKey, data, response.headers['etag']);
        return data;
      }
      throw http.ClientException('Unexpected status ${response.statusCode}');
    } catch (_) {
      // Offline-first fallback: bundled JSON asset ships with the app, so a
      // clean install with zero connectivity still fully works.
      final data = await loadFromBundledAsset();
      await _store(cacheKey, data, null);
      return data;
    }
  }

  static Future<void> _revalidateInBackground(
    String cacheKey,
    String hostedUrl,
    String? etag,
    void Function(dynamic data)? validate,
  ) async {
    try {
      final headers = etag == null
          ? <String, String>{}
          : <String, String>{'If-None-Match': etag};
      final response = await http
          .get(Uri.parse(hostedUrl), headers: headers)
          .timeout(ContentConfig.networkTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Never let a malformed hosted file replace a working cache.
        if (_isValid(data, validate)) {
          await _store(cacheKey, data, response.headers['etag']);
        }
      }
      // 304 Not Modified (or any other non-200) → cache is already current,
      // or hosted content is temporarily unreachable; nothing to do.
    } catch (_) {
      // Offline or hosted URL unreachable — silently keep the existing
      // cache, no error surfaced to the UI (this runs unawaited).
    }
  }

  static bool _isValid(dynamic data, void Function(dynamic data)? validate) {
    if (validate == null) return true;
    try {
      validate(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _store(String cacheKey, dynamic data, String? etag) =>
      ContentCacheBox.instance.put(cacheKey, {
        'data': data,
        'etag': etag,
        'fetchedAt': DateTime.now().toIso8601String(),
      });

  /// Clears a single cached key. Useful for tests, manual cache-busting, or
  /// (later) a "refresh content" action.
  static Future<void> invalidate(String cacheKey) =>
      ContentCacheBox.instance.delete(cacheKey);
}
