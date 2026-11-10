import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/cache_first_loader.dart';

/// Reusable cache-first JSON repository pipeline.
///
/// Concrete repositories only provide the content identity, bundled-asset
/// fallback, and model mapper. Networking, persistent caching, and in-memory
/// memoization stay in one implementation.
class JsonContentRepository<T> {
  final String cacheKey;
  final String hostedUrl;
  final Future<dynamic> Function() loadFromBundledAsset;
  final T Function(dynamic raw) decode;
  Future<dynamic> Function()? _loadRaw;

  T? _cache;
  Future<T>? _pendingLoad;

  JsonContentRepository({
    required this.cacheKey,
    required this.hostedUrl,
    required this.loadFromBundledAsset,
    required this.decode,
    this._loadRaw,
  });

  /// Creates a repository whose offline fallback is a bundled JSON asset.
  factory JsonContentRepository.fromAsset({
    required String cacheKey,
    required String hostedUrl,
    required String assetPath,
    required T Function(dynamic raw) decode,
    Future<dynamic> Function()? loadRaw,
  }) {
    return JsonContentRepository<T>(
      cacheKey: cacheKey,
      hostedUrl: hostedUrl,
      loadFromBundledAsset: () async {
        final source = await rootBundle.loadString(assetPath);
        return json.decode(source);
      },
      decode: decode,
      loadRaw: loadRaw,
    );
  }

  Future<T> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _pendingLoad ??= _loadOnce();
  }

  Future<T> _loadOnce() async {
    try {
      final raw =
          await (_loadRaw?.call() ??
              CacheFirstLoader.load(
                cacheKey: cacheKey,
                hostedUrl: hostedUrl,
                loadFromBundledAsset: loadFromBundledAsset,
              ));
      final decoded = decode(raw);
      _cache = decoded;
      return decoded;
    } finally {
      _pendingLoad = null;
    }
  }

  void clearMemoryCache() => _cache = null;
}
