// lib/src/widgets/segment_badge.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Faza 19 — colorblind-safe segment identifier: a small colored circle
/// with the segment's short text code (`E1`, `E2`, ...) inside it, instead
/// of a plain color-only dot/strip. Used everywhere a segment's color is
/// shown on its own (legend, stage cards, stage detail/map headers), so
/// segments stay distinguishable for users who can't reliably tell
/// #870203 (dark red) apart from #000000 (black) by hue alone.
class SegmentBadge extends StatelessWidget {
  final int order;
  final double size;

  const SegmentBadge({super.key, required this.order, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.colorForStageOrder(order),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        AppColors.shortCodeForStageOrder(order),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
