// lib/src/widgets/elevation_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

class ElevationChart extends StatelessWidget {
  final List<(double, double)> profile; // (distanceKm, elevationM)

  const ElevationChart({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text(S.errorGpx)),
      );
    }

    final spots = profile
        .map((p) => FlSpot(p.$1, p.$2))
        .toList();

    final minEle = profile.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
    final maxEle = profile.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
    final maxDist = profile.last.$1;
    final xInterval = _niceInterval(maxDist);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxDist,
          minY: (minEle - 50).clamp(0, double.infinity),
          maxY: maxEle + 100,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}m',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: xInterval,
                getTitlesWidget: (value, _) => Text(
                  '${value.toStringAsFixed(1)}km',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.green,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.greenLight.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a human-friendly x-axis interval (in km) giving ~4–6 labels.
  double _niceInterval(double maxKm) {
    if (maxKm <= 0) return 1;
    final raw = maxKm / 5;
    const steps = [0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 25.0, 50.0, 100.0];
    for (final s in steps) {
      if (s >= raw) return s;
    }
    return (raw / 10).ceilToDouble() * 10;
  }
}


