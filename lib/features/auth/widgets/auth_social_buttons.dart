import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/apple_auth_service.dart';
import 'package:fitness_app/services/auth_service.dart';

/// "Continue with Google" / "Continue with Apple", then an "or use email"
/// divider — shared by the login and signup screens, matching the
/// prototype's `socialBtns()`. Google signs in through
/// [AuthService.loginWithGoogle] and Apple through
/// [AuthService.loginWithApple]; Apple is shown on iOS only. On the signup
/// screen ([isSignup]) Google refuses an account that already exists.
class AuthSocialButtons extends ConsumerStatefulWidget {
  const AuthSocialButtons({
    super.key,
    this.isSignup = false,
    this.dividerText,
  });

  final bool isSignup;
  final String? dividerText;

  @override
  ConsumerState<AuthSocialButtons> createState() => AuthSocialButtonsState();
}

class AuthSocialButtonsState extends ConsumerState<AuthSocialButtons> {
  bool isGoogleLoading = false;
  bool isAppleLoading = false;

  Future<void> signInWithGoogle() => _signIn(
        (auth) => auth.loginWithGoogle(isSignup: widget.isSignup),
        setLoading: (value) => isGoogleLoading = value,
        isLoading: () => isGoogleLoading || isAppleLoading,
      );

  Future<void> signInWithApple() => _signIn(
        (auth) => auth.loginWithApple(),
        setLoading: (value) => isAppleLoading = value,
        isLoading: () => isGoogleLoading || isAppleLoading,
      );

  Future<void> _signIn(
    Future<bool> Function(AuthService auth) login, {
    required void Function(bool) setLoading,
    required bool Function() isLoading,
  }) async {
    if (isLoading()) return;
    setState(() => setLoading(true));
    try {
      final signedIn = await login(ref.read(authServiceProvider));
      if (signedIn) await ref.read(appFlowProvider.notifier).enterAfterSignIn();
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.secondary,
          leading: Image.asset(
            'assets/images/google_g.png',
            width: 20.r,
            height: 20.r,
          ),
          onPressed: signInWithGoogle,
          isLoading: isGoogleLoading,
        ),
        if (AppleAuthService.showButton) ...[
          10.verticalSpace,
          AppButton(
            label: 'Continue with Apple',
            variant: AppButtonVariant.contrast,
            leading: Icon(
              Icons.apple,
              size: 26.r,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: signInWithApple,
            isLoading: isAppleLoading,
          ),
        ],
        14.verticalSpace,
        AppDividerText(text: widget.dividerText ?? (widget.isSignup ? 'or use email' : 'or continue')),
      ],
    );
  }
}
