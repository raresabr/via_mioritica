// lib/src/widgets/design.dart
// Shared design-system widgets: glass surfaces, motion helpers, skeletons.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';

/// Space the floating glass nav bar occupies at the bottom of the screen
/// (bar height + margin + safe area); scroll views pad themselves by it.
double navBarClearance(BuildContext context) =>
    64 + 14 + navBottomInset(context) + 6;

/// Gap under the floating nav: hugs the home indicator.
double navBottomInset(BuildContext context) {
  final b = MediaQuery.paddingOf(context).bottom;
  return b > 0 ? (b - 24).clamp(4.0, 12.0) : 8;
}

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Frosted-glass surface: backdrop blur + translucent fill + hairline
/// border + soft top highlight.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final bool dark;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double fillOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 24,
    this.dark = false,
    this.padding,
    this.width,
    this.height,
    this.fillOpacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    final base = dark ? AppColors.night : Colors.white;
    final borderColor = (dark ? Colors.white : Colors.white).withValues(
      alpha: dark ? 0.14 : 0.55,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: dark ? 0.10 : 0.35),
                  base.withValues(alpha: fillOpacity),
                ),
                Color.alphaBlend(
                  Colors.white.withValues(alpha: dark ? 0.02 : 0.08),
                  base.withValues(alpha: fillOpacity),
                ),
              ],
            ),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Round glass icon button for use over photos / maps.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool dark;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.dark = true,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final btn = PressableScale(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: GlassContainer(
        radius: size,
        blur: 18,
        dark: dark,
        fillOpacity: dark ? 0.38 : 0.55,
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.48,
          color: dark ? Colors.white : AppColors.night,
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Small uppercase label with wide tracking ("eyebrow" on the website).
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final bool dot;

  const Eyebrow(
    this.text, {
    super.key,
    this.color = AppColors.sun600,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill with icon + label. Works on light surfaces and (glass) on photos.
class PillChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final Color? background;
  final bool glass;

  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.earth,
    this.background,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
    if (glass) {
      return GlassContainer(
        radius: 30,
        blur: 14,
        dark: true,
        fillOpacity: 0.35,
        child: content,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: content,
    );
  }
}

/// Scale-on-press feedback (0.97) with a soft spring back.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 320),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Fade + slide-up entrance. [index] staggers siblings.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double dy;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.dy = 28,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: AppFonts.expo,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    Future<void>.delayed(
      Duration(milliseconds: 60 * widget.index.clamp(0, 8)),
      () {
        if (mounted) _c.forward();
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.dy),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Shimmering placeholder block.
class Skeleton extends StatefulWidget {
  final double? height;
  final double? width;
  final double radius;

  const Skeleton({super.key, this.height, this.width, this.radius = 24});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _c.value * 3, 0),
            end: Alignment(-0.5 + _c.value * 3, 0),
            colors: [
              AppColors.parchment.withValues(alpha: 0.55),
              AppColors.parchment.withValues(alpha: 0.95),
              AppColors.parchment.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder for card lists.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 240});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Skeleton(height: itemHeight),
    );
  }
}

/// Friendly error state with a retry pill.
class ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.parchment,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: AppColors.earth,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.errorLoad,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text(S.retry)),
          ],
        ),
      ),
    );
  }
}

/// Glass sheet container used by every modal bottom sheet.
class GlassSheet extends StatelessWidget {
  final Widget child;
  const GlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Material(
          color: AppColors.cream.withValues(alpha: 0.88),
          shape: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.earth.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large editorial page header (eyebrow + serif title) used on tab screens.
class ScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  const ScreenHeader({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 20,
        24,
        12,
      ),
      child: FadeSlideIn(
        dy: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(eyebrow),
            const SizedBox(height: 10),
            Text(title, style: displayStyle(36)),
          ],
        ),
      ),
    );
  }
}
