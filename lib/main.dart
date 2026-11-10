import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/screens/splash_screen.dart';
import 'src/services/analytics_service.dart';
import 'src/services/content_cache_box.dart';
import 'src/services/crashlytics_service.dart';
import 'src/services/progress_box.dart';
import 'src/services/remote_config_service.dart';
import 'src/services/settings_box.dart';
import 'src/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The four groups below are independent, so run them concurrently to cut
  // cold-start time. Each one handles its own failures.
  await Future.wait([
    _initEnv(),
    _initFirebase(),
    _initOfflineTiles(),
    _initLocalStorage(),
  ]);

  runApp(const ProviderScope(child: ViaMioriticaApp()));
}

/// Loads `.env` for MAPTILER_KEY (gitignored, see README). A
/// `--dart-define=MAPTILER_KEY=...` value always takes precedence, so a
/// missing file is expected in CI/release builds.
Future<void> _initEnv() async {
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('No .env loaded (using --dart-define if provided): $e');
  }
}

/// Firebase + Remote Config (force-update gate), then Crashlytics and
/// Analytics, which must come after `Firebase.initializeApp()`. Everything
/// fails open: the app still works normally without any of them.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RemoteConfigService.init();
  } catch (e) {
    debugPrint('Firebase init failed (running without it): $e');
  }
  await CrashlyticsService.init();
  await AnalyticsService.init();
}

/// FMTC (offline tile caching, GPL-v3 — see LICENSE). Must be initialised
/// before any store/tile-provider/download use. Non-fatal: the map falls
/// back to online-only if it fails (e.g. corrupted cache directory).
Future<void> _initOfflineTiles() async {
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (e) {
    debugPrint('FMTC init failed (online-only maps): $e');
  }
}

/// Hive boxes: disposable content cache (Faza 13), local progress (Faza 15)
/// and one-off UI flags (Faza 20). Opened one after another so the shared
/// `Hive.initFlutter()` call never races.
Future<void> _initLocalStorage() async {
  await ContentCacheBox.init();
  await ProgressBox.init();
  await SettingsBox.init();
}

class ViaMioriticaApp extends StatelessWidget {
  const ViaMioriticaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Via Mioritica',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Faza 16: automatic screen_view analytics on every route change.
      navigatorObservers: [AnalyticsService.observer],
      home: const SplashScreen(),
    );
  }
}
