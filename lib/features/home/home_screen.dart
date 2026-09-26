import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/explore_view.dart';
import 'package:fitness_app/features/home/widgets/today_view.dart';
import 'package:fitness_app/features/profile/widgets/profile_view.dart';
import 'package:fitness_app/features/progress/widgets/progress_view.dart';

/// The app's real home: bottom-tabbed shell around the Today screen.
/// Mine isn't built yet, so it shows a placeholder rather than nothing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int tabIndex = 0;

  static const List<AppNavItemModel> navItems = [
    AppNavItemModel(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Today',
    ),
    AppNavItemModel(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    AppNavItemModel(
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
      label: 'Mine',
    ),
    AppNavItemModel(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Progress',
    ),
    AppNavItemModel(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tabIndex,
          children: [
            const TodayView(firstName: 'Anand'),
            const ExploreView(),
            _ComingSoonTab(label: navItems[2].label),
            const ProgressView(),
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: navItems,
        currentIndex: tabIndex,
        onTap: (index) => setState(() => tabIndex = index),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppInsets.page,
      child: AppEmptyState(
        icon: Icons.hourglass_top_rounded,
        title: '$label is coming soon',
        message: "This tab isn't built yet.",
      ),
    ),
  );
}
