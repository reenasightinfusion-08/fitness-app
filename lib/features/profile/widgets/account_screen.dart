import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/widgets/change_password_screen.dart';

/// Matches the prototype's `screens.account`: sign-in details, a masked
/// password row that opens the change-password flow, and the two exits — log out and
/// delete account.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends ConsumerState<AccountScreen> {
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    refreshProfile();
  }

  /// Reloads the account from the server so the email and sign-in methods
  /// shown here are current, even if the profile didn't load at sign-in.
  Future<void> refreshProfile() async {
    try {
      final res = await ref.read(authServiceProvider).getMe();
      final user = (res['user'] ?? res['data'] ?? res) as Map<String, dynamic>;
      if (mounted) {
        ref.read(onboardingProfileProvider.notifier).loadFromApi(user);
      }
    } catch (e) {
      debugPrint('[Account] Could not refresh the profile: $e');
    }
  }

  Future<void> confirmDelete() async {
    final confirmed = await AppBottomSheet.confirm(
      context,
      title: 'Delete your account?',
      message:
          'This permanently removes your profile, history, routines and '
          'stretches.',
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
    final flow = ref.read(appFlowProvider.notifier);
    await flow.resetUserState();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    flow.showWelcome();
    messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final userEmail = profile.email;

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
                  AppSettingRow(title: 'Email', subtitle: userEmail),
                  AppSettingRow(
                    title: 'Signed in with',
                    subtitle: profile.signInLabel,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            if (profile.hasPassword) ...[
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
            ],
            20.verticalSpace,
            AppButton(
              label: 'Log out',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                await ref.read(authServiceProvider).logout();
                final flow = ref.read(appFlowProvider.notifier);
                await flow.resetUserState();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  flow.showWelcome();
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
