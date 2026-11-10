// lib/src/widgets/stages_sheet.dart
import 'package:flutter/material.dart';

import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import 'design.dart';
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
      backgroundColor: Colors.transparent,
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
      builder: (context, controller) => GlassSheet(
        child: ListView(
          controller: controller,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            ListTile(
              key: const Key('stagesSheetAll'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(S.fullMapAllStages, style: displayStyle(19)),
              subtitle: Text(
                '${stages.length} ${S.fullMapLegendTitle.toLowerCase()} · '
                '${totalKm.toStringAsFixed(1)} km ${S.fullMapDocumented}',
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 16),
            for (final stage in stages)
              ListTile(
                key: Key('stagesSheet_${stage.id}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: SegmentBadge(order: stage.order, size: 36),
                title: Text(
                  stage.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '${stage.distanceKm.toStringAsFixed(1)} km · '
                  '${stage.durationEstimate}',
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.brown,
                ),
                onTap: () => Navigator.of(context).pop(stage),
              ),
          ],
        ),
      ),
    );
  }
}
