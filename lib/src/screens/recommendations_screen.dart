// lib/src/screens/recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

IconData _iconForCategory(RecommendationCategory category) {
  switch (category) {
    case RecommendationCategory.echipament:
      return Icons.backpack_outlined;
    case RecommendationCategory.siguranta:
      return Icons.shield_outlined;
    case RecommendationCategory.apa:
      return Icons.water_drop_outlined;
    case RecommendationCategory.vreme:
      return Icons.cloud_outlined;
    case RecommendationCategory.general:
      return Icons.info_outline;
  }
}

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.recommendationsTitle),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: recsAsync.when(
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
                onPressed: () => ref.invalidate(recommendationsProvider),
                child: const Text(S.retry),
              ),
            ],
          ),
        ),
        data: (recs) {
          if (recs.isEmpty) {
            return const Center(child: Text(S.recommendationsEmpty));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recs.length,
            itemBuilder: (ctx, i) {
              final rec = recs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    _iconForCategory(rec.category),
                    color: AppColors.green,
                  ),
                  title: Text(
                    rec.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(rec.body, style: const TextStyle(height: 1.4)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
