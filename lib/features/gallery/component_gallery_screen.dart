import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_buttons_section.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_cards_section.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_form_section.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_player_section.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_progress_section.dart';
import 'package:fitness_app/features/gallery/widgets/gallery_selection_section.dart';

/// Every shared component on one scrollable page, for visual QA in both themes.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      ComponentGalleryScreenState();
}

class ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
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
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppTopBar(
        center: const Center(child: AppBrandLogo()),
        trailing: AppIconButton(
          icon: brightness == Brightness.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          tooltip: 'Toggle theme',
          onPressed: () =>
              ref.read(themeModeProvider.notifier).toggle(brightness),
        ),
      ),
      body: ListView(
        padding: AppInsets.page,
        children: [
          const AppPageHeader(
            eyebrow: 'Design system',
            title: 'Loosen components',
            hint:
                'Every shared widget in lib/core/widgets. Toggle the theme from the top right.',
          ),
          28.verticalSpace,
          const GalleryButtonsSection(),
          28.verticalSpace,
          const GalleryFormSection(),
          28.verticalSpace,
          const GallerySelectionSection(),
          28.verticalSpace,
          const GalleryCardsSection(),
          28.verticalSpace,
          const GalleryProgressSection(),
          28.verticalSpace,
          const GalleryPlayerSection(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: navItems,
        currentIndex: tabIndex,
        onTap: (index) => setState(() => tabIndex = index),
      ),
    );
  }
}
