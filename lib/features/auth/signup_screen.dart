import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/auth/widgets/auth_social_buttons.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.signup`. Email/password are local
/// `TextEditingController`s — form input is UI-only state and doesn't
/// belong in a provider. Submits to [AuthService.signup], starts a
/// [PendingAuthController] for the verify-email step, and hands off to
/// [AppFlowController.showVerifyEmail].
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends ConsumerState<SignupScreen> {
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
    if (isLoading) return;
    setState(() => hasSubmitted = true);
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    setState(() => isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signup(email: email, password: passwordController.text);
      if (!mounted) return;
      ref.read(pendingAuthProvider.notifier).start(email);
      ref.read(appFlowProvider.notifier).showVerifyEmail();
    } on AuthException catch (e) {
      debugPrint('[SignupScreen] AuthException: ${e.message}');
      if (mounted) AppSnackBar.showError(context, e.message);
    } catch (e, stack) {
      debugPrint('[SignupScreen] Unexpected error: $e\n$stack');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Unexpected error occurred. Check debug console.',
        );
      }
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
        title: 'Create account',
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
                  hint: 'At least 8 characters',
                  variant: AppTextFieldVariant.password,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: AppValidators.password,
                  onSubmitted: (_) => submit(),
                  autovalidateMode: hasSubmitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                ),
                18.verticalSpace,
                AppButton(
                  label: 'Create account',
                  onPressed: submit,
                  isLoading: isLoading,
                ),
                14.verticalSpace,
                AppInlineLink(
                  prefix: 'Already have an account?',
                  linkText: 'Log in',
                  onTap: () => ref.read(appFlowProvider.notifier).showLogin(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
