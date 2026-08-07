// lib/src/screens/stage_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage_model.dart';
import '../models/poi_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/poi_card.dart';
import '../widgets/trail_map.dart';
import 'map_screen.dart';

class StageDetailScreen extends ConsumerWidget {
  final StageModel stage;

  const StageDetailScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevAsync = ref.watch(elevationProfileProvider(stage.gpxFile));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar with map preview ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            title: Text(
              stage.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                      compact: true,
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

                  // Elevation profile
                  _SectionTitle(S.sectionElevation),
                  const SizedBox(height: 8),
                  elevAsync.when(
                    loading: () => const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator())),
                    error: (_, err) => const SizedBox(
                        height: 80,
                        child: Center(child: Text(S.errorGpx))),
                    data: (profile) => ElevationChart(profile: profile),
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

