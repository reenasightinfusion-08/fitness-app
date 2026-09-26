import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/app_flow_provider.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/profile/models/profile_data.dart';

/// Matches the prototype's `screens.profile`: identity header, an account
/// menu, and log out.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _notBuiltYet(BuildContext context) =>
      AppSnackBar.show(context, "That screen isn't built yet.");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return ListView(
      padding: AppInsets.page,
      children: [
        Row(
          children: [
            const AppAvatar(name: ProfileDemoData.name),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ProfileDemoData.name, style: AppTextStyle.titleLarge),
                  Text(
                    '${ProfileDemoData.email} · '
                    '${ProfileDemoData.isPremium ? 'Premium' : 'Free plan'}',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
        20.verticalSpace,
        AppCard(
          variant: AppCardVariant.list,
          child: Column(
            children: [
              for (final item in ProfileDemoData.menu)
                AppSettingRow(
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: () => _notBuiltYet(context),
                  showDivider: item != ProfileDemoData.menu.last,
                ),
            ],
          ),
        ),
        20.verticalSpace,
        AppButton(
          label: 'Log out',
          variant: AppButtonVariant.secondary,
          onPressed: () => ref.read(appFlowProvider.notifier).showWelcome(),
        ),
      ],
    );
  }
}
