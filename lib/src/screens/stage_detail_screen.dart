// lib/src/screens/stage_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage_model.dart';
import '../models/poi_model.dart';
import '../providers/progress_providers.dart';
import '../providers/providers.dart';
import '../services/analytics_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
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
        appBar: AppBar(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          title: Text(stage.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          title: Text(stage.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: _StageDetailBody(stage: stage),
      ),
      data: (_) => _StageDetailBody(stage: stage),
    );
  }
}

class _StageDetailBody extends ConsumerWidget {
  final StageModel stage;

  const _StageDetailBody({required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(
      progressProvider.select((ids) => ids.contains(stage.id)),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar with map preview ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentBadge(order: stage.order, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    stage.name,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(stage: stage),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrailMap(
                      gpxAssetPath: stage.gpxFile,
                      stageId: stage.id,
                      compact: true,
                      segmentColor: AppColors.colorForStageOrder(stage.order),
                    ),
                    // Tap hint overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Hartă completă',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technical stats row
                  _StatsRow(stage: stage),
                  const SizedBox(height: 16),

                  // Progress tracking (Faza 15 — local, no account)
                  _CompletedToggle(
                    isCompleted: isCompleted,
                    onChanged: (value) {
                      ref
                          .read(progressProvider.notifier)
                          .setCompleted(stage.id, value);
                      // Faza 16: anonymous, stage-id-only usage signal.
                      if (value) {
                        AnalyticsService.logStageCompleted(stage.id);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Offline map download
                  OfflineDownloadCard(
                    stageId: stage.id,
                    gpxAssetPath: stage.gpxFile,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _SectionTitle(S.sectionDescription),
                  const SizedBox(height: 8),
                  Text(
                    stage.description.isNotEmpty
                        ? stage.description
                        : S.contentInProgress,
                    style: const TextStyle(
                        fontSize: 14, height: 1.6, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 24),

                  // POI sections
                  ..._buildPoiSection(
                      S.sectionCazare,
                      stage.pois
                          .where((p) => p.type == PoiType.cazare)
                          .toList()),
                  ..._buildPoiSection(
                      S.sectionPopas,
                      stage.pois
                          .where((p) => p.type == PoiType.popas)
                          .toList()),
                  ..._buildPoiSection(
                      S.sectionObiective,
                      stage.pois
                          .where((p) => p.type == PoiType.obiectiv)
                          .toList()),
                  ..._buildPoiSection(
                      S.sectionRecomandari,
                      stage.pois
                          .where((p) => p.type == PoiType.recomandare)
                          .toList()),

                  const SizedBox(height: 40),
                ],
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
      const SizedBox(height: 8),
      if (pois.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(S.noPois,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        )
      else
        ...pois.map((p) => PoiCard(poi: p)),
      const SizedBox(height: 20),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.green,
      ),
    );
  }
}

/// Faza 15 — checkbox to mark a stage as personally completed. Purely
/// local (no account), backed by [progressProvider]/`HiveProgressRepository`.
class _CompletedToggle extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  const _CompletedToggle({
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCompleted
          ? AppColors.green.withValues(alpha: 0.1)
          : AppColors.textMuted.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!isCompleted),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                activeColor: AppColors.green,
                onChanged: (value) => onChanged(value ?? false),
              ),
              Expanded(
                child: Text(
                  isCompleted
                      ? S.progressCompletedLabel
                      : S.progressMarkCompleted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.green
                        : AppColors.textDark,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.green, size: 20),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
              icon: Icons.straighten,
              value: '${stage.distanceKm} km',
              label: S.stageDistance),
          _Stat(
              icon: Icons.trending_up,
              value: '+${stage.elevationGainM} m',
              label: S.stageGain,
              color: AppColors.green),
          _Stat(
              icon: Icons.trending_down,
              value: '-${stage.elevationLossM} m',
              label: S.stageLoss,
              color: AppColors.brown),
          _Stat(
              icon: Icons.schedule,
              value: stage.durationEstimate,
              label: S.stageDuration),
        ],
      ),
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
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

