import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/splash_screen.dart';
import 'src/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for MAPTILER_KEY (ignored in git, see README)
  // In CI pass --dart-define=MAPTILER_KEY=xxx instead of .env
  await dotenv.load(fileName: '.env').catchError((_) {});

  // Initialise FMTC (offline tile caching). Must happen before any FMTC
  // usage (store creation, tile provider, downloads). GPL-v3 licensed —
  // see LICENSE at repo root.
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (_) {
    // Non-fatal: app still works online-only if FMTC fails to initialise
    // (e.g. corrupted cache directory on a previous crash).
  }

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
      home: const SplashScreen(),
    );
  }
}
