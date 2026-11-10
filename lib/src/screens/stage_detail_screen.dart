// lib/src/screens/stage_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/poi_model.dart';
import '../models/stage_model.dart';
import '../providers/progress_providers.dart';
import '../providers/providers.dart';
import '../services/analytics_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/design.dart';
import '../widgets/offline_download_card.dart';
import '../widgets/poi_card.dart';
import '../widgets/segment_badge.dart';
import '../widgets/trail_map.dart';
import 'map_screen.dart';

class StageDetailScreen extends ConsumerWidget {
  final StageModel stage;

  const StageDetailScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI/UX polish: wait for the GPX track to be parsed *before* building
    // the full layout. Previously the whole screen (stats, POIs, ...)
    // appeared instantly while `TrailMap` kept showing its own internal
    // spinner in the map area a moment later — a jarring two-step
    // transition. By gating here, `TrailMap` finds the provider already
    // resolved and never shows its own loading state, so the screen
    // appears complete in a single step.
    final trackAsync = ref.watch(trackPointsProvider(stage.gpxFile));

    return trackAsync.when(
      loading: () => Scaffold(
        body: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: SafeArea(child: Skeleton(height: 320, radius: 32)),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              child: const _BackButton(),
            ),
          ],
        ),
      ),
      error: (e, _) => _StageDetailBody(stage: stage),
      data: (_) => _StageDetailBody(stage: stage),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    icon: Icons.arrow_back_ios_new_rounded,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onTap: () => Navigator.maybePop(context),
  );
}

class _StageDetailBody extends ConsumerWidget {
  final StageModel stage;

  const _StageDetailBody({required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(
      progressProvider.select((ids) => ids.contains(stage.id)),
    );

    final top = MediaQuery.paddingOf(context).top;
    final pois = <(String, PoiType)>[
      (S.sectionCazare, PoiType.cazare),
      (S.sectionPopas, PoiType.popas),
      (S.sectionObiective, PoiType.obiectiv),
      (S.sectionRecomandari, PoiType.recomandare),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.night,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            leadingWidth: 72,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BackButton(),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, c) {
                final collapsedH = top + 64;
                final t = ((c.maxHeight - collapsedH) / (380 - collapsedH))
                    .clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.translate(
                      offset: Offset(0, (1 - t) * 40),
                      child: Hero(
                        tag: 'stage-cover-${stage.id}',
                        child: Image.asset(
                          stage.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: AppColors.earth),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            AppColors.night.withValues(alpha: 0.92),
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                    // Solid night scrim fades in as the header collapses.
                    Opacity(
                      opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                      child: const ColoredBox(color: AppColors.night),
                    ),
                    Positioned(
                      top: top,
                      left: 72,
                      right: 24,
                      height: 64,
                      child: Opacity(
                        opacity: (1 - t * 2.2).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: displayStyle(19, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 48,
                      child: Opacity(
                        opacity: t,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SegmentBadge(order: stage.order, size: 28),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Eyebrow(
                                    stage.difficulty,
                                    color: AppColors.sun,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              stage.name,
                              style: displayStyle(
                                34,
                                color: Colors.white,
                                height: 1.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Content sheet overlapping the hero
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  MediaQuery.paddingOf(context).bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(child: _StatsRow(stage: stage)),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 1,
                      child: _CompletedToggle(
                        isCompleted: isCompleted,
                        onChanged: (value) {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(progressProvider.notifier)
                              .setCompleted(stage.id, value);
                          if (value) {
                            AnalyticsService.logStageCompleted(stage.id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    FadeSlideIn(index: 2, child: _MapPreview(stage: stage)),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 3,
                      child: OfflineDownloadCard(
                        stageId: stage.id,
                        gpxAssetPath: stage.gpxFile,
                      ),
                    ),
                    const SizedBox(height: 36),

                    _SectionTitle(S.sectionDescription),
                    const SizedBox(height: 14),
                    Text(
                      stage.description.isNotEmpty
                          ? stage.description
                          : S.contentInProgress,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 36),

                    for (final (title, type) in pois)
                      ..._buildPoiSection(
                        title,
                        stage.pois.where((p) => p.type == type).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPoiSection(String title, List<PoiModel> pois) {
    return [
      _SectionTitle(title),
      const SizedBox(height: 12),
      if (pois.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            S.noPois,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        )
      else
        ...pois.map((p) => PoiCard(poi: p)),
      const SizedBox(height: 32),
    ];
  }
}

class _MapPreview extends StatelessWidget {
  final StageModel stage;
  const _MapPreview({required this.stage});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => MapScreen(stage: stage)),
      ),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.earth.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AbsorbPointer(
                child: TrailMap(
                  gpxAssetPath: stage.gpxFile,
                  stageId: stage.id,
                  compact: true,
                  segmentColor: AppColors.colorForStageOrder(stage.order),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GlassContainer(
                  radius: 30,
                  blur: 16,
                  dark: true,
                  fillOpacity: 0.45,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Hartă completă',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.sun,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(text, style: displayStyle(26)),
      ],
    );
  }
}

/// Local (no account) completed toggle backed by [progressProvider].
class _CompletedToggle extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  const _CompletedToggle({required this.isCompleted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => onChanged(!isCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: AppFonts.expo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isCompleted
                ? AppColors.green
                : AppColors.earth.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.sun : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.sun
                      : AppColors.earth.withValues(alpha: 0.35),
                  width: 1.8,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AppColors.night,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isCompleted
                    ? S.progressCompletedLabel
                    : S.progressMarkCompleted,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.white : AppColors.night,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final StageModel stage;
  const _StatsRow({required this.stage});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat(
        icon: Icons.straighten_rounded,
        value: '${stage.distanceKm} km',
        label: S.stageDistance,
      ),
      _Stat(
        icon: Icons.trending_up_rounded,
        value: '+${stage.elevationGainM} m',
        label: S.stageGain,
        color: AppColors.green,
      ),
      _Stat(
        icon: Icons.trending_down_rounded,
        value: '-${stage.elevationLossM} m',
        label: S.stageLoss,
        color: AppColors.brown,
      ),
      _Stat(
        icon: Icons.schedule_rounded,
        value: stage.durationEstimate,
        label: S.stageDuration,
        color: AppColors.sky,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: items,
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.night,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.earth.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: displayStyle(19, height: 1.1)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
