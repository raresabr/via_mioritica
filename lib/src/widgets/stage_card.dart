// lib/src/widgets/stage_card.dart
import 'package:flutter/material.dart';
import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

class StageCard extends StatelessWidget {
  final StageModel stage;
  final VoidCallback onTap;

  const StageCard({super.key, required this.stage, required this.onTap});

  Color _difficultyColor() {
    switch (stage.difficulty.toLowerCase()) {
      case 'ușor':
      case 'usor':
        return Colors.green.shade700;
      case 'mediu':
        return Colors.orange.shade700;
      case 'dificil':
        return Colors.red.shade700;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            SizedBox(
              height: 140,
              width: double.infinity,
                child: Image.asset(
                stage.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, _) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(Icons.landscape, size: 48, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: '${stage.distanceKm} ${S.stageKm}',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.trending_up,
                        label: '+${stage.elevationGainM}${S.stageM}',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.trending_down,
                        label: '-${stage.elevationLossM}${S.stageM}',
                        color: AppColors.brown,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _difficultyColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stage.difficulty,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _difficultyColor()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(stage.durationEstimate,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}



