import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';

/// "Continue with Google" / "Continue with Apple", then an "or use email"
/// divider — shared by the login and signup screens, matching the
/// prototype's `socialBtns()`. Neither provider is wired up yet, so both
/// just surface that with a snack bar.
class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Continue with Google',
          variant: AppButtonVariant.secondary,
          onPressed: () => _notComingYet(context, 'Google'),
        ),
        10.verticalSpace,
        AppButton(
          label: 'Continue with Apple',
          variant: AppButtonVariant.secondary,
          onPressed: () => _notComingYet(context, 'Apple'),
        ),
        14.verticalSpace,
        const AppDividerText(text: 'or use email'),
      ],
    );
  }

  void _notComingYet(BuildContext context, String provider) =>
      AppSnackBar.show(context, '$provider sign-in is coming soon.');
}
