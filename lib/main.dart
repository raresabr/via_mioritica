import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/splash_screen.dart';
import 'src/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for MAPTILER_KEY (ignored in git, see README)
  // In CI pass --dart-define=MAPTILER_KEY=xxx instead of .env
  await dotenv.load(fileName: '.env').catchError((_) {});

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
