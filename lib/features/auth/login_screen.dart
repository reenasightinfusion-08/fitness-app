import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/auth/widgets/auth_social_buttons.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.login`. Email/password are local
/// `TextEditingController`s — form input is UI-only state and doesn't
/// belong in a provider. Submits to [AuthService.login]; on success it
/// hands off to [AppFlowController.enterApp].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// Fields only start validating live once a submit has actually been
  /// attempted, so errors don't flash up while the user is still typing.
  bool hasSubmitted = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => hasSubmitted = true);
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      await ref.read(authServiceProvider).login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (mounted) await ref.read(appFlowProvider.notifier).enterAfterSignIn();
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Log in',
        onBack: () => ref.read(appFlowProvider.notifier).showWelcome(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthSocialButtons(),
                18.verticalSpace,
                AppTextField(
                  controller: emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: AppValidators.email,
                  autovalidateMode: hasSubmitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                ),
                14.verticalSpace,
                AppTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Your password',
                  variant: AppTextFieldVariant.password,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: AppValidators.required,
                  onSubmitted: (_) => submit(),
                  autovalidateMode: hasSubmitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                ),
                6.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'Forgot password?',
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    isExpanded: false,
                    onPressed: () =>
                        ref.read(appFlowProvider.notifier).showForgotPassword(),
                  ),
                ),
                18.verticalSpace,
                AppButton(
                  label: 'Log in',
                  onPressed: submit,
                  isLoading: isLoading,
                ),
                14.verticalSpace,
                AppInlineLink(
                  prefix: 'New here?',
                  linkText: 'Create an account',
                  onTap: () => ref.read(appFlowProvider.notifier).showSignup(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
