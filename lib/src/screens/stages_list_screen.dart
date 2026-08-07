// lib/src/screens/stages_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/progress_providers.dart';
import '../utils/app_strings.dart';
import '../utils/app_colors.dart';
import '../widgets/stage_card.dart';
import 'stage_detail_screen.dart';

class StagesListScreen extends ConsumerWidget {
  const StagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);
    final completedStageIds = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.navGhid),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/placeholders/logo_placeholder.png',
              height: 32,
              errorBuilder: (ctx, err, _) =>
                  const Icon(Icons.terrain, color: Colors.white),
            ),
          ),
        ],
      ),
      body: stagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 8),
              const Text(S.errorLoad),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(stagesProvider),
                child: const Text(S.retry),
              ),
            ],
          ),
        ),
        data: (stages) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: stages.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return _ProgressSummary(
                totalStages: stages.length,
                completedCount: stages
                    .where((s) => completedStageIds.contains(s.id))
                    .length,
              );
            }
            final stage = stages[i - 1];
            return StageCard(
              stage: stage,
              isCompleted: completedStageIds.contains(stage.id),
              onToggleCompleted: (value) =>
                  ref.read(progressProvider.notifier).setCompleted(
                        stage.id,
                        value,
                      ),
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => StageDetailScreen(stage: stage),
                ),
              ),
            );
          },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount/$totalStages ${S.progressSummary}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.cream,
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

