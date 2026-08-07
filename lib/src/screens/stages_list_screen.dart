// lib/src/screens/stages_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_strings.dart';
import '../utils/app_colors.dart';
import '../widgets/stage_card.dart';
import 'stage_detail_screen.dart';

class StagesListScreen extends ConsumerWidget {
  const StagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.appName),
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
          itemCount: stages.length,
          itemBuilder: (ctx, i) => StageCard(
            stage: stages[i],
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => StageDetailScreen(stage: stages[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

