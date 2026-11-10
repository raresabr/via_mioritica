// lib/src/widgets/stage_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stage_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import 'design.dart';
import 'segment_badge.dart';

/// Full-bleed photo card: image, bottom gradient, serif title and glass
/// stat pills over the photo.
class StageCard extends StatelessWidget {
  final StageModel stage;
  final VoidCallback onTap;
  final bool isCompleted;

  /// Allows toggling "completed" directly from the list, without
  /// navigating to the detail screen.
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
        return const Color(0xFF9CC46B);
      case 'mediu':
        return AppColors.sun;
      case 'dificil':
        return const Color(0xFFFF7B72);
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.975,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.earth.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'stage-cover-${stage.id}',
                child: Image.asset(
                  stage.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, _) => Container(
                    color: AppColors.earth,
                    child: const Center(
                      child: Icon(
                        Icons.landscape_rounded,
                        size: 56,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.35, 1],
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0xE61D1A12),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: GlassContainer(
                  radius: 30,
                  blur: 14,
                  dark: true,
                  fillOpacity: 0.35,
                  padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentBadge(order: stage.order, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${stage.distanceKm} ${S.stageKm}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _CompletedBadge(
                  isCompleted: isCompleted,
                  onTap: onToggleCompleted == null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          onToggleCompleted!(!isCompleted);
                        },
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _difficultyColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stage.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: _difficultyColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            stage.durationEstimate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: displayStyle(
                        25,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PillChip(
                          glass: true,
                          icon: Icons.trending_up_rounded,
                          label: '+${stage.elevationGainM}${S.stageM}',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        PillChip(
                          glass: true,
                          icon: Icons.trending_down_rounded,
                          label: '-${stage.elevationLossM}${S.stageM}',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.sun, width: 2.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Always-visible completed toggle. Has its own hit-test area so a tap
/// does not also trigger the card's `onTap`.
class _CompletedBadge extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;

  const _CompletedBadge({required this.isCompleted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isCompleted ? S.progressUnmarkSemantics : S.progressMarkSemantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.sun
                  : Colors.black.withValues(alpha: 0.32),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? AppColors.sun
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(isCompleted),
                size: 20,
                color: isCompleted ? AppColors.night : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
