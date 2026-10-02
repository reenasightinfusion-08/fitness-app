import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

/// "Continue with Google" / "Continue with Apple", then an "or use email"
/// divider — shared by the login and signup screens, matching the
/// prototype's `socialBtns()`. Google signs in through
/// [AuthService.loginWithGoogle]; Apple isn't wired up yet, so it just
/// surfaces that with a snack bar.
class AuthSocialButtons extends ConsumerStatefulWidget {
  const AuthSocialButtons({super.key});

  @override
  ConsumerState<AuthSocialButtons> createState() => AuthSocialButtonsState();
}

class AuthSocialButtonsState extends ConsumerState<AuthSocialButtons> {
  bool isGoogleLoading = false;

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading) return;
    setState(() => isGoogleLoading = true);
    try {
      final signedIn = await ref.read(authServiceProvider).loginWithGoogle();
      if (signedIn) await ref.read(appFlowProvider.notifier).enterAfterSignIn();
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.secondary,
          onPressed: signInWithGoogle,
          isLoading: isGoogleLoading,
        ),
        10.verticalSpace,
        AppButton(
          label: 'Continue with Apple',
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              AppSnackBar.show(context, 'Apple sign-in is coming soon.'),
        ),
        14.verticalSpace,
        const AppDividerText(text: 'or use email'),
      ],
    );
  }
}
