// lib/src/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF2D6A4F);
  static const greenLight = Color(0xFF52B788);
  static const brown = Color(0xFF795548);
  static const cream = Color(0xFFF5F1E9);
  static const textDark = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF6B6B6B);

  /// Placeholder per-segment palette used on the full-route map & legend
  /// (Faza 8) until the final alternating brand colors (#870203/#000000)
  /// are wired in (Faza 9) — see [colorForStageOrder].
  static const List<Color> segmentPalette = [green, brown];

  /// Deterministic color for a stage/segment based on its `order` field
  /// (not array/JSON position), so coloring stays stable regardless of
  /// how stages.json is reordered.
  static Color colorForStageOrder(int order) =>
      segmentPalette[order % segmentPalette.length];
}

