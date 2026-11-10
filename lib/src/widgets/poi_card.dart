// lib/src/widgets/poi_card.dart
import 'package:flutter/material.dart';
import '../models/poi_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'design.dart';

class PoiCard extends StatelessWidget {
  final PoiModel poi;
  const PoiCard({super.key, required this.poi});

  IconData _icon() {
    switch (poi.type) {
      case PoiType.cazare:
        return Icons.hotel_rounded;
      case PoiType.popas:
        return Icons.table_bar_rounded;
      case PoiType.obiectiv:
        return Icons.photo_camera_rounded;
      case PoiType.recomandare:
        return Icons.star_border_rounded;
    }
  }

  Color _iconColor() {
    switch (poi.type) {
      case PoiType.cazare:
        return AppColors.sky;
      case PoiType.popas:
        return AppColors.brown;
      case PoiType.obiectiv:
        return AppColors.green;
      case PoiType.recomandare:
        return AppColors.sun600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => _showDetail(context),
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.earth.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  if (poi.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      poi.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.brown),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, ctrl) => GlassSheet(
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _iconColor().withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_icon(), color: _iconColor(), size: 26),
                ),
                const SizedBox(height: 14),
                Text(poi.name, style: displayStyle(26)),
                if (poi.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    poi.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (poi.photos.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: poi.photos.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          poi.photos[i],
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
