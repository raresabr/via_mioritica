// lib/src/widgets/stages_sheet.dart
import 'package:flutter/material.dart';

import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import 'segment_badge.dart';

/// Bottom sheet listing the documented stages. Pops with the chosen
/// [StageModel], or with null when "whole trail" is picked.
class StagesSheet extends StatelessWidget {
  const StagesSheet({super.key, required this.stages});

  final List<StageModel> stages;

  static Future<StageModel?> show(
    BuildContext context,
    List<StageModel> stages,
  ) {
    return showModalBottomSheet<StageModel?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StagesSheet(stages: stages),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalKm = stages.fold<double>(0, (sum, s) => sum + s.distanceKm);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            key: const Key('stagesSheetAll'),
            leading: const Icon(Icons.route, color: AppColors.green),
            title: const Text(
              S.fullMapAllStages,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${stages.length} ${S.fullMapLegendTitle.toLowerCase()} · '
              '${totalKm.toStringAsFixed(1)} km ${S.fullMapDocumented}',
            ),
            onTap: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1),
          for (final stage in stages)
            ListTile(
              key: Key('stagesSheet_${stage.id}'),
              leading: SegmentBadge(order: stage.order, size: 28),
              title: Text(stage.name),
              subtitle: Text(
                '${stage.distanceKm.toStringAsFixed(1)} km · '
                '${stage.durationEstimate}',
              ),
              onTap: () => Navigator.of(context).pop(stage),
            ),
        ],
      ),
    );
  }
}
