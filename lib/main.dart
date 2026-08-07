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

  // Load .env for MAPTILER_KEY (ignored in git, see README)
  // In CI pass --dart-define=MAPTILER_KEY=xxx instead of .env
  await dotenv.load(fileName: '.env').catchError((_) {});

  // Faza 14: Firebase + Remote Config, for the force-update gate. Non-fatal
  // if it fails (e.g. offline on first launch) — RemoteConfigService fails
  // open (never blocks the app just because init failed).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await RemoteConfigService.init();
  } catch (_) {
    // App still works normally; isForceUpdateRequired stays false.
  }

  // Faza 16: crash reporting + usage analytics. Must come after
  // Firebase.initializeApp() above; both fail open (no crash
  // reporting/analytics for the session) if Firebase itself didn't
  // initialise (e.g. offline first launch).
  await CrashlyticsService.init();
  await AnalyticsService.init();

  // Initialise FMTC (offline tile caching). Must happen before any FMTC
  // usage (store creation, tile provider, downloads). GPL-v3 licensed —
  // see LICENSE at repo root.
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (_) {
    // Non-fatal: app still works online-only if FMTC fails to initialise
    // (e.g. corrupted cache directory on a previous crash).
  }

  // Initialise the Hive content cache (Faza 13: cache-first content
  // loading — see lib/src/utils/cache_first_loader.dart).
  await ContentCacheBox.init();

  // Initialise the Hive progress box (Faza 15: local-only "stage
  // completed" tracking, no account required).
  await ProgressBox.init();

  // Initialise the Hive settings box (Faza 20: one-off local UI-state
  // flags, e.g. "has the offline-download onboarding tip been shown?").
  await SettingsBox.init();

  runApp(
    const ProviderScope(
      child: ViaMioriticaApp(),
    ),
  );
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
