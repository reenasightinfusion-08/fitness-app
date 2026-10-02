import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/explore_view.dart';
import 'package:fitness_app/features/home/widgets/today_view.dart';
import 'package:fitness_app/features/mine/mine_view.dart';
import 'package:fitness_app/features/profile/widgets/profile_view.dart';
import 'package:fitness_app/features/progress/widgets/progress_view.dart';

/// The app's real home: bottom-tabbed shell around the Today screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
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
    final tabIndex = ref.watch(homeTabProvider).index;
    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tabIndex,
          children: [
            const TodayView(),
            const ExploreView(),
            const MineView(),
            const ProgressView(),
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: navItems,
        currentIndex: tabIndex,
        onTap: (index) =>
            ref.read(homeTabProvider.notifier).show(HomeTab.values[index]),
      ),
    );
  }
}
