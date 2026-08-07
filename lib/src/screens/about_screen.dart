// lib/src/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../widgets/brand_footer.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.navDespreNoi),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: aboutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 8),
              const Text(S.errorLoad),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(aboutContentProvider),
                child: const Text(S.retry),
              ),
            ],
          ),
        ),
        data: (about) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/main.jpg',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.green,
                  child: const Center(
                    child: Icon(Icons.terrain, size: 56, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                about.title.isNotEmpty ? about.title : S.appName,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppColors.green),
              ),
              const SizedBox(height: 12),
              Text(
                about.body.isNotEmpty ? about.body : S.contentInProgress,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Center(
                child: BrandFooter(
                  text: about.footerText.isNotEmpty
                      ? about.footerText
                      : S.aboutFooterFallback,
                  url: about.footerUrl.isNotEmpty
                      ? about.footerUrl
                      : 'https://stag-line.com/',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
