// lib/src/screens/photo_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

/// null = no filter (show all photos).
final _selectedStageFilterProvider = StateProvider<String?>((ref) => null);

class PhotoGalleryScreen extends ConsumerWidget {
  const PhotoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider);
    final stagesAsync = ref.watch(stagesProvider);
    final selectedStageId = ref.watch(_selectedStageFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.albumTitle),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          stagesAsync.maybeWhen(
            data: (stages) => _StageFilterBar(
              stages: stages,
              selectedStageId: selectedStageId,
              onSelect: (id) =>
                  ref.read(_selectedStageFilterProvider.notifier).state = id,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: photosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text(S.errorLoad),
                  ],
                ),
              ),
              data: (photos) {
                final filtered = selectedStageId == null
                    ? photos
                    : photos
                        .where((p) => p.stageId == selectedStageId)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(S.albumEmpty, textAlign: TextAlign.center),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final photo = filtered[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        photo.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.cream,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.textMuted),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StageFilterBar extends StatelessWidget {
  final List<StageModel> stages;
  final String? selectedStageId;
  final ValueChanged<String?> onSelect;

  const _StageFilterBar({
    required this.stages,
    required this.selectedStageId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text(S.albumFilterAll),
              selected: selectedStageId == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(stage.name),
                selected: selectedStageId == stage.id,
                onSelected: (_) => onSelect(stage.id),
              ),
            ),
        ],
      ),
    );
  }
}
