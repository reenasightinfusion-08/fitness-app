import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/models/profile_data.dart';
import 'package:fitness_app/features/profile/providers/premium_provider.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/features/profile/widgets/change_password_screen.dart';
import 'package:fitness_app/services/reminder_notification_service.dart';

/// Matches the prototype's `screens.account`: sign-in details, a masked
/// password row that opens the change-password flow, subscription status, and the two exits — log out and
/// delete account.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends ConsumerState<AccountScreen> {
  bool isDeleting = false;

  Future<void> confirmDelete() async {
    final confirmed = await AppBottomSheet.confirm(
      context,
      title: 'Delete your account?',
      message:
          'This permanently removes your profile, history, routines and '
          'stretches. Any Premium purchase ends too.',
      confirmLabel: 'Delete everything',
      isDestructive: true,
    );
    if (!confirmed || isDeleting) return;
    setState(() => isDeleting = true);
    try {
      await ref.read(authServiceProvider).deleteAccount();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => isDeleting = false);
        AppSnackBar.show(context, e.message);
      }
      return;
    }
    ref.invalidate(customRoutinesProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(hurtStretchesProvider);
    ref.invalidate(onboardingProfileProvider);
    ref.invalidate(premiumProvider);
    ref.invalidate(sessionSettingsProvider);
    await ReminderNotificationService.instance.cancelAll();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(appFlowProvider.notifier).showWelcome();
    messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPremium = ref.watch(premiumProvider);

    final profile = ref.watch(onboardingProfileProvider);
    final userEmail = profile.email.isEmpty ? ProfileDemoData.email : profile.email;

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Account & security',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppInsets.page,
          children: [
            AppCard(
              variant: AppCardVariant.list,
              child: Column(
                children: [
                  AppSettingRow(
                    title: userEmail,
                    subtitle: 'Email',
                  ),
                  const AppSettingRow(
                    title: 'Email and password',
                    subtitle: 'Signed in with',
                    showDivider: false,
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            AppCard(
              variant: AppCardVariant.list,
              child: AppSettingRow(
                title: 'Password',
                subtitle: '••••••••',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(email: userEmail),
                  ),
                ),
                showDivider: false,
              ),
            ),
            16.verticalSpace,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Subscription', style: AppTextStyle.titleMedium),
                  6.verticalSpace,
                  Text(
                    isPremium
                        ? 'Premium, one-time purchase. Nothing will renew.'
                        : 'Free plan. Nothing to cancel.',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
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
                ref.invalidate(remindersProvider);
                ref.invalidate(hurtStretchesProvider);
                ref.invalidate(sessionSettingsProvider);
                await ReminderNotificationService.instance.cancelAll();
                if (context.mounted) {
                  ref.read(appFlowProvider.notifier).showWelcome();
                }
              },
            ),
            4.verticalSpace,
            AppButton(
              label: 'Delete my account and data',
              variant: AppButtonVariant.dangerText,
              isLoading: isDeleting,
              onPressed: isDeleting ? null : confirmDelete,
            ),
          ],
        ),
      ),
    );
  }
}
