// lib/src/widgets/stage_card.dart
import 'package:flutter/material.dart';
import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import 'segment_badge.dart';

class StageCard extends StatelessWidget {
  final StageModel stage;
  final VoidCallback onTap;
  final bool isCompleted;

  /// UI/UX polish: allows toggling "completed" directly from the list,
  /// without navigating to the detail screen. Optional so other call
  /// sites (if any) keep working with a purely read-only badge.
  final ValueChanged<bool>? onToggleCompleted;

  const StageCard({
    super.key,
    required this.stage,
    required this.onTap,
    this.isCompleted = false,
    this.onToggleCompleted,
  });

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
      // UI/UX polish: completed stages get a green border + soft green
      // shadow/background tint, in addition to the checkmark badge — the
      // "done" state should be obvious at a glance in a long list, not
      // just from a small icon in a corner.
      shape: isCompleted
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.green, width: 2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      color: isCompleted ? AppColors.green.withValues(alpha: 0.05) : null,
      shadowColor: isCompleted
          ? AppColors.green.withValues(alpha: 0.4)
          : null,
      elevation: isCompleted ? 3 : 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segment color accent (Faza 9) — same color used on the
            // full-trail map & legend, so a stage is identifiable at a
            // glance across both screens.
            Container(
              height: 4,
              width: double.infinity,
              color: AppColors.colorForStageOrder(stage.order),
            ),
            // Cover image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.asset(
                    stage.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, _) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.landscape,
                            size: 48, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                // Faza 19: colorblind-safe segment shortCode badge,
                // paired with the color strip above (top-left, out of the
                // way of the "completed" checkmark badge on top-right).
                Positioned(
                  top: 8,
                  left: 8,
                  child: SegmentBadge(order: stage.order, size: 24),
                ),
                // UI/UX polish: always-visible, tappable completed toggle
                // (previously a static badge shown only when completed).
                // Wrapped in its own Material/InkResponse so the tap does
                // NOT also trigger the card's onTap navigation.
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CompletedBadge(
                    isCompleted: isCompleted,
                    onTap: onToggleCompleted == null
                        ? null
                        : () => onToggleCompleted!(!isCompleted),
                  ),
                ),
              ],
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

/// Always-visible top-right completed-toggle badge on [StageCard]. Uses
/// its own `Material`/`InkWell` hit-test area so tapping it does not also
/// trigger the card's `onTap` (navigation to the detail screen).
class _CompletedBadge extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;

  const _CompletedBadge({required this.isCompleted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isCompleted
          ? S.progressUnmarkSemantics
          : S.progressMarkSemantics,
      child: Material(
        color: isCompleted ? AppColors.green : Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isCompleted ? Icons.check : Icons.check_circle_outline,
              size: 16,
              color: isCompleted ? Colors.white : AppColors.textMuted,
            ),
          ),
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



