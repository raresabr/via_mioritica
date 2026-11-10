// lib/src/screens/stages_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/progress_providers.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/design.dart';
import '../widgets/stage_card.dart';
import 'stage_detail_screen.dart';

class StagesListScreen extends ConsumerWidget {
  const StagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);
    final completedStageIds = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: stagesAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) =>
            ErrorRetry(onRetry: () => ref.invalidate(stagesProvider)),
        data: (stages) => CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(
              child: ScreenHeader(eyebrow: S.navGhidShort, title: S.navGhid),
            ),
            SliverToBoxAdapter(
              child: _ProgressSummary(
                totalStages: stages.length,
                completedCount: stages
                    .where((s) => completedStageIds.contains(s.id))
                    .length,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                navBarClearance(context) + 8,
              ),
              sliver: SliverList.separated(
                itemCount: stages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (ctx, i) {
                  final stage = stages[i];
                  return FadeSlideIn(
                    index: i,
                    child: StageCard(
                      stage: stage,
                      isCompleted: completedStageIds.contains(stage.id),
                      onToggleCompleted: (value) => ref
                          .read(progressProvider.notifier)
                          .setCompleted(stage.id, value),
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute<void>(
                          builder: (_) => StageDetailScreen(stage: stage),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faza 15 — overall completion banner ("X din Y etape finalizate, Z%"),
/// shown at the top of the stage list. Reads straight off [progressProvider]
/// so it updates instantly when a stage is toggled from the detail screen.
class _ProgressSummary extends StatelessWidget {
  final int totalStages;
  final int completedCount;

  const _ProgressSummary({
    required this.totalStages,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (totalStages == 0) return const SizedBox.shrink();
    final percent = completedCount / totalStages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.night,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent * 100),
                  duration: const Duration(milliseconds: 900),
                  curve: AppFonts.expo,
                  builder: (_, v, _) => Text(
                    '${v.round()}%',
                    style: displayStyle(44, color: AppColors.sun, height: 1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '$completedCount/$totalStages ${S.progressSummary}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 900),
                curve: AppFonts.expo,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.sun),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
