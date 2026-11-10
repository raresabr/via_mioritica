// lib/src/screens/photo_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/photo_model.dart';
import '../models/stage_model.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/design.dart';

/// null = no filter (show all photos).
class _StageFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final _selectedStageFilterProvider = NotifierProvider<_StageFilter, String?>(
  _StageFilter.new,
);

class PhotoGalleryScreen extends ConsumerWidget {
  const PhotoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider);
    final stagesAsync = ref.watch(stagesProvider);
    final selectedStageId = ref.watch(_selectedStageFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const ScreenHeader(eyebrow: S.navAlbumShort, title: S.albumTitle),
          stagesAsync.maybeWhen(
            data: (stages) => _StageFilterBar(
              stages: stages,
              selectedStageId: selectedStageId,
              onSelect: (id) =>
                  ref.read(_selectedStageFilterProvider.notifier).select(id),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: photosAsync.when(
              loading: () =>
                  const Padding(padding: EdgeInsets.all(16), child: Skeleton()),
              error: (e, _) =>
                  ErrorRetry(onRetry: () => ref.invalidate(photosProvider)),
              data: (photos) {
                final filtered = selectedStageId == null
                    ? photos
                    : photos
                          .where((p) => p.stageId == selectedStageId)
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(S.albumEmpty, textAlign: TextAlign.center),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    navBarClearance(context) + 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final photo = filtered[i];
                    return FadeSlideIn(
                      index: i % 6,
                      dy: 20,
                      child: PressableScale(
                        onTap: () => _openViewer(ctx, filtered, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            photo.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.parchment,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, List<PhotoModel> photos, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => _PhotoViewer(photos: photos, index: index),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<PhotoModel> photos;
  final int index;
  const _PhotoViewer({required this.photos, required this.index});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.index,
  );
  late int _page = widget.index;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.asset(
                  widget.photos[i].assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GlassIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                PillChip(
                  glass: true,
                  label: '${_page + 1} / ${widget.photos.length}',
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageFilterBar extends StatelessWidget {
  final List<StageModel> stages;
  final String? selectedStageId;
  final ValueChanged<String?> onSelect;

  const _StageFilterBar({
    required this.stages,
    required this.selectedStageId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterPill(
            label: S.albumFilterAll,
            selected: selectedStageId == null,
            onTap: () => onSelect(null),
          ),
          for (final stage in stages)
            _FilterPill(
              label: stage.name,
              selected: selectedStageId == stage.id,
              onTap: () => onSelect(stage.id),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: PressableScale(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: AppFonts.expo,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.night : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected
                    ? AppColors.night
                    : AppColors.earth.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.cream : AppColors.earth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
