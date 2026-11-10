// lib/src/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/brand_footer.dart';
import '../widgets/design.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: aboutAsync.when(
        loading: () => const Skeleton(radius: 0),
        error: (e, _) =>
            ErrorRetry(onRetry: () => ref.invalidate(aboutContentProvider)),
        data: (about) {
          final title = about.title.isNotEmpty ? about.title : S.appName;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 12,
                    16,
                    0,
                  ),
                  child: FadeSlideIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1200 / 851,
                        child: Image.asset(
                          'assets/images/romania_map.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.green,
                            child: const Center(
                              child: Icon(
                                Icons.terrain_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.cream,
                  padding: EdgeInsets.fromLTRB(
                    28,
                    24,
                    28,
                    navBarClearance(context),
                  ),
                  child: FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow(
                          S.navDespreNoiShort,
                          color: AppColors.sun600,
                        ),
                        const SizedBox(height: 10),
                        Text(title, style: displayStyle(36, height: 1.08)),
                        const SizedBox(height: 20),
                        Text(
                          about.body.isNotEmpty
                              ? about.body
                              : S.contentInProgress,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontSize: 18, height: 1.7),
                        ),
                        const SizedBox(height: 28),
                        PressableScale(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.parchment),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    S.privacyPolicyLinkLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.night,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: AppColors.earth,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
