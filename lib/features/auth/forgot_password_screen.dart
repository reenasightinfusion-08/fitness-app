import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.forgot`. Submitting requests a reset
/// code from [AuthService.forgotPassword], starts a [PendingAuthController]
/// "reset" and hands off to the reset-password screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (isLoading) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    setState(() => isLoading = true);
    try {
      await ref.read(authServiceProvider).forgotPassword(email: email);
      if (!mounted) return;
      ref.read(pendingAuthProvider.notifier).start(email);
      ref.read(appFlowProvider.notifier).showResetPassword();
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
        title: 'Reset password',
        onBack: () => ref.read(appFlowProvider.notifier).showLogin(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Forgot your password?',
                  style: AppTextStyle.headline,
                ),
                6.verticalSpace,
                Text(
                  "Enter your email and we'll send a code to reset it.",
                  style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
                ),
                18.verticalSpace,
                AppTextField(
                  controller: emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  validator: AppValidators.email,
                  onSubmitted: (_) => submit(),
                ),
                18.verticalSpace,
                AppButton(
                  label: 'Send reset code',
                  onPressed: submit,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
