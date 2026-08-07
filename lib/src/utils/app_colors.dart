// lib/src/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF2D6A4F);
  static const greenLight = Color(0xFF52B788);
  static const brown = Color(0xFF795548);
  static const cream = Color(0xFFF5F1E9);
  static const textDark = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF6B6B6B);

  /// Alternating brand palette per segment/stage (Faza 9), in order:
  /// #870203 (dark red) / #000000 (black). Both are dark enough for
  /// white text on top (contrast) and dark enough to read as accents on
  /// light backgrounds (cards, legend swatches).
  static const List<Color> segmentPalette = [
    Color(0xFF870203),
    Color(0xFF000000),
  ];

  /// Deterministic color for a stage/segment based on its `order` field
  /// (not array/JSON position), so coloring stays stable regardless of
  /// how stages.json is reordered.
  static Color colorForStageOrder(int order) =>
      segmentPalette[order % segmentPalette.length];

  /// Deterministic, colorblind-safe short text label per segment (Faza
  /// 19), e.g. `E1`, `E2`, ... — used everywhere `colorForStageOrder` is
  /// used, so segments stay distinguishable even for users who can't
  /// reliably tell #870203 (dark red) apart from #000000 (black) by hue
  /// alone. `E` = "Etapa" (Romanian for "Stage").
  static String shortCodeForStageOrder(int order) => 'E${order + 1}';
}

