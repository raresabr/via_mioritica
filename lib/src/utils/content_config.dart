// lib/src/utils/content_config.dart
/// Faza 17 — hosted JSON content configuration.
///
/// Points at the same JSON files bundled as app assets, served raw from the
/// public GitHub repo. Single source of truth: editing a file under
/// `assets/data/` in the repo and pushing to `main` updates the hosted
/// content within minutes (GitHub's raw CDN cache is ~5 min) — no separate
/// CMS/backend, no new app release needed for content-only changes.
class ContentConfig {
  static const String _rawBaseUrl =
      'https://raw.githubusercontent.com/raresabr/via_mioritica/main/assets/data';

  static String hostedUrlFor(String fileName) => '$_rawBaseUrl/$fileName';

  /// Timeout for both the initial fetch (cache miss) and the background
  /// revalidation check (cache hit) — kept short so a slow/unreachable
  /// network never meaningfully delays the offline-first fallback.
  static const Duration networkTimeout = Duration(seconds: 5);
}
