import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';

class GalleryButtonsSection extends StatefulWidget {
  const GalleryButtonsSection({super.key});

  @override
  State<GalleryButtonsSection> createState() => GalleryButtonsSectionState();
}

class GalleryButtonsSectionState extends State<GalleryButtonsSection> {
  bool isSaving = false;
  bool isFavorite = false;

  Future<void> simulateSave() async {
    setState(() => isSaving = true);
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) AppSnackBar.showSuccess(context, 'Routine saved.');
    } catch (error) {
      debugPrint('simulateSave error: $error');
      if (mounted) AppSnackBar.showError(context, 'Couldn’t save. Try again.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> confirmDelete() async {
    final isConfirmed = await AppBottomSheet.confirm(
      context,
      title: 'Delete this routine?',
      message: 'This removes it from My routines. Your history stays.',
      confirmLabel: 'Delete routine',
      isDestructive: true,
    );
    if (isConfirmed && mounted) AppSnackBar.show(context, 'Routine deleted.');
  }

  @override
  Widget build(BuildContext context) => AppSectionWrapper(
    title: 'Buttons',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Start',
          icon: Icons.play_arrow_rounded,
          onPressed: () {},
        ),
        10.verticalSpace,
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
        10.verticalSpace,
        AppButton(
          label: 'Save routine',
          isLoading: isSaving,
          onPressed: simulateSave,
        ),
        10.verticalSpace,
        const AppButton(label: 'Continue (disabled)', onPressed: null),
        AppButton(
          label: 'Explore with a sample account',
          variant: AppButtonVariant.text,
          onPressed: () {},
        ),
        AppButton(
          label: 'Delete routine',
          variant: AppButtonVariant.dangerText,
          onPressed: confirmDelete,
        ),
        10.verticalSpace,
        Row(
          children: [
            AppButton(
              label: 'Add',
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
              isExpanded: false,
              onPressed: () {},
            ),
            10.horizontalSpace,
            AppButton(
              label: 'Edit',
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              isExpanded: false,
              onPressed: () {},
            ),
            const Spacer(),
            AppIconButton(
              icon: Icons.favorite_border_rounded,
              activeIcon: Icons.favorite_rounded,
              isActive: isFavorite,
              tooltip: 'Favourite',
              onPressed: () => setState(() => isFavorite = !isFavorite),
            ),
          ],
        ),
        12.verticalSpace,
        AppInlineLink(
          prefix: 'Already have an account?',
          linkText: 'Log in',
          onTap: () {},
        ),
      ],
    ),
  );
}
