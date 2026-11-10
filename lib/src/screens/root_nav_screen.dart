// lib/src/screens/root_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/design.dart';
import '../widgets/offline_onboarding_sheet.dart';
import 'about_screen.dart';
import 'full_trail_map_screen.dart';
import 'photo_gallery_screen.dart';
import 'recommendations_screen.dart';
import 'stages_list_screen.dart';

/// Root 5-tab bottom navigation (Faza 8): Despre Noi / Hartă traseu /
/// Recomandări practice / Ghidul Călătorului / Album foto.
class RootNavScreen extends StatefulWidget {
  const RootNavScreen({super.key});

  @override
  State<RootNavScreen> createState() => _RootNavScreenState();
}

class _RootNavScreenState extends State<RootNavScreen> {
  int _index = 0;

  static const _screens = [
    AboutScreen(),
    FullTrailMapScreen(),
    RecommendationsScreen(),
    StagesListScreen(),
    PhotoGalleryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Faza 20: one-time offline-download onboarding tip, shown after the
    // first frame so a valid BuildContext/Navigator is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OfflineOnboardingSheet.showIfFirstLaunch(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _GlassNavBar(
        index: _index,
        onChanged: (i) {
          if (i == _index) return;
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.info_outline_rounded, Icons.info_rounded, S.navDespreNoiShort),
  _NavItem(Icons.map_outlined, Icons.map_rounded, S.navHartaTraseuShort),
  _NavItem(
    Icons.checklist_rounded,
    Icons.checklist_rtl_rounded,
    S.navRecomandariShort,
  ),
  _NavItem(Icons.hiking_rounded, Icons.hiking_rounded, S.navGhidShort),
  _NavItem(
    Icons.photo_library_outlined,
    Icons.photo_library_rounded,
    S.navAlbumShort,
  ),
];

/// Floating frosted-glass tab bar with a sliding sun-coloured pill; the
/// active tab expands to reveal its label.
class _GlassNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _GlassNavBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 520);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, navBottomInset(context)),
      child: GlassContainer(
        radius: 34,
        blur: 28,
        dark: true,
        fillOpacity: 0.62,
        height: 64,
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, c) {
            final total = c.maxWidth;
            final active = (total * 0.36).clamp(96.0, 140.0);
            final other = (total - active) / (_navItems.length - 1);
            double left = 0;
            for (var i = 0; i < index; i++) {
              left += other;
            }
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: AppFonts.expo,
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: active,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.sun,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sun.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _navItems.length; i++)
                      AnimatedContainer(
                        duration: duration,
                        curve: AppFonts.expo,
                        width: i == index ? active : other,
                        child: _NavButton(
                          item: _navItems[i],
                          selected: i == index,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.night
        : Colors.white.withValues(alpha: 0.72);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  key: ValueKey(selected),
                  size: 23,
                  color: color,
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: AppFonts.expo,
                  alignment: Alignment.centerLeft,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.night,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
