import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Matches the prototype's `screens.reset`. On success there's no
/// backend to actually change a password against, so it just clears the
/// pending state and returns to login with a confirmation toast — same
/// as the mock.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      ResetPasswordScreenState();
}

class ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  String? codeError;

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit(PendingAuth pending) {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (codeController.text.trim() != pending.code) {
      setState(() => codeError = "That code doesn't match.");
      return;
    }
    ref.read(pendingAuthProvider.notifier).clear();
    ref.read(appFlowProvider.notifier).showLogin();
    AppSnackBar.showSuccess(
      context,
      'Password updated. Log in with your new password.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = ref.watch(pendingAuthProvider);

    if (pending == null) {
      return Scaffold(
        backgroundColor: colors.ground,
        appBar: AppTopBar(
          title: 'New password',
          onBack: () => ref.read(appFlowProvider.notifier).showLogin(),
        ),
        body: Padding(
          padding: AppInsets.page,
          child: AppEmptyState(
            icon: Icons.lock_reset_rounded,
            title: 'No reset in progress',
            message: 'Request a reset code first.',
            actionLabel: 'Forgot password',
            onAction: () =>
                ref.read(appFlowProvider.notifier).showForgotPassword(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'New password',
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
                Text('Set a new password', style: AppTextStyle.headline),
                6.verticalSpace,
                Text.rich(
                  TextSpan(
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
                    children: [
                      const TextSpan(text: 'For '),
                      TextSpan(
                        text: pending.email,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                18.verticalSpace,
                AppNote(
                  tone: AppTone.warm,
                  message: 'Prototype: your reset code is ${pending.code}',
                ),
                18.verticalSpace,
                AppTextField(
                  controller: codeController,
                  label: 'Code',
                  hint: '6-digit code',
                  variant: AppTextFieldVariant.otp,
                  validator: AppValidators.otp,
                  onChanged: (_) {
                    if (codeError != null) setState(() => codeError = null);
                  },
                ),
                if (codeError != null) ...[
                  6.verticalSpace,
                  Text(
                    codeError!,
                    style: AppTextStyle.meta.copyWith(color: colors.danger),
                  ),
                ],
                14.verticalSpace,
                AppTextField(
                  controller: passwordController,
                  label: 'New password',
                  hint: 'At least 8 characters',
                  variant: AppTextFieldVariant.password,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: AppValidators.password,
                  onSubmitted: (_) => submit(pending),
                ),
                18.verticalSpace,
                AppButton(
                  label: 'Save new password',
                  onPressed: () => submit(pending),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
