// lib/src/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../widgets/brand_footer.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return Scaffold(
      backgroundColor: AppColors.parchment,
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
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textMuted,
              ),
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
        data: (about) => CustomScrollView(
          slivers: [
            // UI/UX polish: hero image edge-to-edge (no padding), flush
            // against the AppBar — previously wrapped in the same
            // padded SingleChildScrollView as the rest of the content,
            // leaving a visible margin on every side including the top.
            SliverToBoxAdapter(
              child: Image.asset(
                'assets/images/romania_map.webp',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: AppColors.green,
                  child: const Center(
                    child: Icon(Icons.terrain, size: 56, color: Colors.white),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  Text(
                    about.title.isNotEmpty ? about.title : S.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['serif'],
                      color: AppColors.segmentRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    about.body.isNotEmpty ? about.body : S.contentInProgress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.6,
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['serif'],
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.privacy_tip_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      label: const Text(
                        S.privacyPolicyLinkLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
