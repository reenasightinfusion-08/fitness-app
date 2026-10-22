import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/legal_links.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/features/profile/widgets/account_screen.dart';
import 'package:fitness_app/features/profile/widgets/edit_profile_screen.dart';
import 'package:fitness_app/features/profile/widgets/reminders_screen.dart';
import 'package:fitness_app/features/profile/widgets/settings_screen.dart';

/// Matches the prototype's `screens.profile`: identity header, an account
/// menu, and log out. Each row now opens its real screen; the subtitles
/// for Reminders reads live off its provider.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final reminders = ref.watch(remindersProvider);
    final profile = ref.watch(onboardingProfileProvider);
    final displayName = profile.name.isEmpty ? 'Runner' : profile.name;
    final displayEmail = profile.email.isNotEmpty
        ? profile.email
        : profile.country;
    final onReminders = reminders.where((r) => r.isOn).toList();
    final remindersSubtitle = reminders.isEmpty
        ? 'No reminder set yet'
        : onReminders.isEmpty
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
        'Voice, music, streak day',
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
        'Privacy Policy',
        'How your information is used',
        () => LegalLinks.open(context, LegalLinks.privacy),
      ),
      (
        'Terms of Use',
        'Rules and health notice',
        () => LegalLinks.open(context, LegalLinks.terms),
      ),
      (
        'Help & support',
        'Contact us, common questions',
        () => LegalLinks.open(context, LegalLinks.support),
      ),
    ];

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 720.0 : double.infinity,
        ),
        child: ListView(
          padding: isTablet
              ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0)
              : AppInsets.page,
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
                      if (displayEmail.isNotEmpty)
                        Text(
                          displayEmail,
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
                debugPrint('[LOGOUT] 1. Starting logout');
                await ref.read(authServiceProvider).logout();
                debugPrint('[LOGOUT] 2. Logged out of authService');
                final flow = ref.read(appFlowProvider.notifier);
                debugPrint('[LOGOUT] 3. Got flow notifier');
                await flow.resetUserState();
                debugPrint('[LOGOUT] 4. Reset user state');
                flow.showWelcome();
                debugPrint('[LOGOUT] 5. Called showWelcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}
