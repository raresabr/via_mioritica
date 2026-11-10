// lib/src/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Palette taken from the Simplicity Retreat web design.
  static const green = Color(0xFF547130); // moss
  static const greenLight = Color(0xFF7C9A52);
  static const brown = Color(0xFF7A705A); // earth-500
  static const cream = Color(0xFFF6F1E4);
  static const parchment = Color(0xFFE9DFC6); // sand
  static const night = Color(0xFF1D1A12);
  static const night800 = Color(0xFF26221A);
  static const earth = Color(0xFF3F3929);
  static const sun = Color(0xFFEDB234);
  static const sun300 = Color(0xFFF5CF78);
  static const sun600 = Color(0xFFC98F12);
  static const sky = Color(0xFF216BA5);
  static const segmentRed = Color(0xFF870203);
  static const textDark = Color(0xFF1D1A12);
  static const textMuted = Color(0xFF7A705A);

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
