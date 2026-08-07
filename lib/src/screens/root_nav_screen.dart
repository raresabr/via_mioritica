// lib/src/screens/root_nav_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
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
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: S.navDespreNoiShort,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: S.navHartaTraseuShort,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            label: S.navRecomandariShort,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hiking_outlined),
            label: S.navGhidShort,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: S.navAlbumShort,
          ),
        ],
      ),
    );
  }
}
