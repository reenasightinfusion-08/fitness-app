import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/models/profile_data.dart';
import 'package:fitness_app/features/profile/providers/premium_provider.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/services/reminder_notification_service.dart';

/// Matches the prototype's `screens.account`: sign-in details, a change
/// password form, subscription status, and the two exits — log out and
/// delete account.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends ConsumerState<AccountScreen> {
  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void updatePassword() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    currentPasswordController.clear();
    newPasswordController.clear();
    AppSnackBar.showSuccess(context, 'Password updated.');
  }

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
    if (!confirmed) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.show(context, e.message);
      return;
    }
    ref.invalidate(customRoutinesProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(hurtStretchesProvider);
    ref.invalidate(onboardingProfileProvider);
    ref.invalidate(premiumProvider);
    await ReminderNotificationService.instance.cancelAll();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(appFlowProvider.notifier).showSignup();
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
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Change password', style: AppTextStyle.titleMedium),
                    14.verticalSpace,
                    AppTextField(
                      controller: currentPasswordController,
                      label: 'Current password',
                      hint: 'Current password',
                      variant: AppTextFieldVariant.password,
                      autofillHints: const [AutofillHints.password],
                      validator: AppValidators.required,
                    ),
                    14.verticalSpace,
                    AppTextField(
                      controller: newPasswordController,
                      label: 'New password',
                      hint: 'At least 8 characters',
                      variant: AppTextFieldVariant.password,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: AppValidators.password,
                      onSubmitted: (_) => updatePassword(),
                    ),
                    16.verticalSpace,
                    AppButton(
                      label: 'Update password',
                      variant: AppButtonVariant.secondary,
                      onPressed: updatePassword,
                    ),
                  ],
                ),
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
              onPressed: confirmDelete,
            ),
          ],
        ),
      ),
    );
  }
}
