import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/providers/premium_provider.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/features/profile/widgets/account_screen.dart';
import 'package:fitness_app/features/profile/widgets/edit_profile_screen.dart';
import 'package:fitness_app/features/profile/widgets/premium_screen.dart';
import 'package:fitness_app/features/profile/widgets/reminders_screen.dart';
import 'package:fitness_app/features/profile/widgets/settings_screen.dart';

/// Matches the prototype's `screens.profile`: identity header, an account
/// menu, and log out. Each row now opens its real screen; the subtitles
/// for Reminders and Premium read live off their providers.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPremium = ref.watch(premiumProvider);
    final reminders = ref.watch(remindersProvider);
    final profile = ref.watch(onboardingProfileProvider);
    final displayName = profile.name.isEmpty ? 'Runner' : profile.name;
    final displayEmail = profile.email.isNotEmpty ? profile.email : profile.country;
    final onReminders = reminders.where((r) => r.isOn).toList();
    final remindersSubtitle = onReminders.isEmpty
        ? 'Off'
        : onReminders.map((r) => r.time.format(context)).join(', ');

    final menu = <(String, String, VoidCallback)>[
      (
        'Edit profile',
        'Body, injuries, equipment, goals, time',
        () => _open(context, const EditProfileScreen()),
      ),
      (
        'Session settings',
        'Voice, music, hold and transition times, streak day',
        () => _open(context, const SettingsScreen()),
      ),
      (
        'Reminders',
        remindersSubtitle,
        () => _open(context, const RemindersScreen()),
      ),
      (
        'Account & security',
        'Password, sign-in, delete account',
        () => _open(context, const AccountScreen()),
      ),
      (
        'Premium',
        isPremium ? 'Active. Thank you!' : '₹999 once, or ₹149/month',
        () => _open(context, const PremiumScreen()),
      ),
    ];

    return ListView(
      padding: AppInsets.page,
      children: [
        Row(
          children: [
            AppAvatar(name: displayName),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: AppTextStyle.titleLarge),
                  Text(
                    '${displayEmail.isEmpty ? "" : "$displayEmail · "}'
                    '${isPremium ? 'Premium' : 'Free plan'}',
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
              for (final item in menu)
                AppSettingRow(
                  title: item.$1,
                  subtitle: item.$2,
                  onTap: item.$3,
                  showDivider: item != menu.last,
                ),
            ],
          ),
        ),
        20.verticalSpace,
        AppButton(
          label: 'Log out',
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            await ref.read(authServiceProvider).logout();
            ref.invalidate(customRoutinesProvider);
            ref.invalidate(favoritesProvider);
            if (context.mounted) {
              ref.read(appFlowProvider.notifier).showWelcome();
            }
          },
        ),
      ],
    );
  }
}
