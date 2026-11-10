// lib/src/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Typography + motion tokens shared by every screen.
class AppFonts {
  static const display = 'Fraunces';
  static const body = 'InstrumentSans';

  static const expo = Cubic(0.16, 1, 0.3, 1);
}

TextStyle displayStyle(
  double size, {
  Color color = AppColors.night,
  FontWeight weight = FontWeight.w500,
  double height = 1.1,
}) => TextStyle(
  fontFamily: AppFonts.display,
  fontSize: size,
  fontWeight: weight,
  height: height,
  letterSpacing: -size * 0.02,
  color: color,
);

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.green,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.green,
        onPrimary: Colors.white,
        secondary: AppColors.sun,
        onSecondary: AppColors.night,
        surface: AppColors.cream,
        onSurface: AppColors.night,
        surfaceContainerHighest: AppColors.parchment,
        outlineVariant: AppColors.parchment,
      );

  TextStyle body(
    double size,
    FontWeight w,
    double h, {
    Color c = AppColors.night,
    double ls = 0,
  }) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: size,
    fontWeight: w,
    height: h,
    letterSpacing: ls,
    color: c,
  );

  final textTheme = TextTheme(
    displayLarge: displayStyle(40),
    displayMedium: displayStyle(34),
    displaySmall: displayStyle(30),
    headlineLarge: displayStyle(28),
    headlineMedium: displayStyle(24),
    headlineSmall: displayStyle(21),
    titleLarge: displayStyle(20, weight: FontWeight.w600, height: 1.2),
    titleMedium: body(16, FontWeight.w600, 1.3),
    titleSmall: body(14, FontWeight.w600, 1.3),
    bodyLarge: body(16.5, FontWeight.w400, 1.6),
    bodyMedium: body(15, FontWeight.w400, 1.55),
    bodySmall: body(13, FontWeight.w400, 1.45, c: AppColors.textMuted),
    labelLarge: body(14, FontWeight.w600, 1.2, ls: 0.2),
    labelMedium: body(12, FontWeight.w600, 1.2, ls: 0.4),
    labelSmall: body(11, FontWeight.w600, 1.2, ls: 1.4),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.cream,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.night,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: displayStyle(24),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.earth.withValues(alpha: 0.08)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.night,
        foregroundColor: AppColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sun,
        foregroundColor: AppColors.night,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.night,
        shape: const StadiumBorder(),
        side: BorderSide(color: AppColors.earth.withValues(alpha: 0.25)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.green,
      linearTrackColor: AppColors.parchment,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      modalBackgroundColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.earth.withValues(alpha: 0.1),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.night,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.cream),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
