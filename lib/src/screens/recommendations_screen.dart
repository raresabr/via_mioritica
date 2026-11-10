// lib/src/screens/recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/design.dart';

IconData _iconForCategory(RecommendationCategory category) {
  switch (category) {
    case RecommendationCategory.echipament:
      return Icons.backpack_rounded;
    case RecommendationCategory.siguranta:
      return Icons.shield_rounded;
    case RecommendationCategory.apa:
      return Icons.water_drop_rounded;
    case RecommendationCategory.vreme:
      return Icons.cloud_rounded;
    case RecommendationCategory.general:
      return Icons.info_rounded;
  }
}

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: recsAsync.when(
        loading: () => const SkeletonList(count: 5, itemHeight: 120),
        error: (e, _) =>
            ErrorRetry(onRetry: () => ref.invalidate(recommendationsProvider)),
        data: (recs) => CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(
              child: ScreenHeader(
                eyebrow: S.navRecomandariShort,
                title: S.recommendationsTitle,
              ),
            ),
            if (recs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(S.recommendationsEmpty)),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  navBarClearance(context) + 8,
                ),
                sliver: SliverList.separated(
                  itemCount: recs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => FadeSlideIn(
                    index: i,
                    child: _RecCard(rec: recs[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  final RecommendationModel rec;
  const _RecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.earth.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sun.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconForCategory(rec.category),
              color: AppColors.sun600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title, style: displayStyle(20, height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  rec.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.earth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
