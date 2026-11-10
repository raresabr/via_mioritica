// lib/src/widgets/poi_card.dart
import 'package:flutter/material.dart';
import '../models/poi_model.dart';
import '../utils/app_colors.dart';

class PoiCard extends StatelessWidget {
  final PoiModel poi;
  const PoiCard({super.key, required this.poi});

  IconData _icon() {
    switch (poi.type) {
      case PoiType.cazare:
        return Icons.hotel_outlined;
      case PoiType.popas:
        return Icons.table_bar_outlined;
      case PoiType.obiectiv:
        return Icons.photo_camera_outlined;
      case PoiType.recomandare:
        return Icons.star_border_rounded;
    }
  }

  Color _iconColor() {
    switch (poi.type) {
      case PoiType.cazare:
        return Colors.indigo;
      case PoiType.popas:
        return AppColors.brown;
      case PoiType.obiectiv:
        return AppColors.green;
      case PoiType.recomandare:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _iconColor().withValues(alpha: 0.12),
          child: Icon(_icon(), color: _iconColor(), size: 20),
        ),
        title: Text(
          poi.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: poi.description.isNotEmpty
            ? Text(
                poi.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        onTap: () => _showDetail(context),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(_icon(), color: _iconColor()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (poi.description.isNotEmpty) Text(poi.description),
              if (poi.photos.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: poi.photos.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        poi.photos[i],
                        width: 220,
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
    );
  }
}
