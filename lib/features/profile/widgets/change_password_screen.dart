import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

enum ChangePasswordStep { current, code, newPassword }

/// Changes the signed-in user's password. The user types the current one; if
/// they've forgotten it, a code is emailed to the account, and once that is
/// verified they can choose a new password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      ChangePasswordScreenState();
}

class ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final codeController = TextEditingController();
  final newController = TextEditingController();
  ChangePasswordStep step = ChangePasswordStep.current;
  bool isLoading = false;
  bool isSendingCode = false;
  String? errorText;

  @override
  void dispose() {
    currentController.dispose();
    codeController.dispose();
    newController.dispose();
    super.dispose();
  }

  void goTo(ChangePasswordStep next) => setState(() {
    step = next;
    errorText = null;
  });

  void back() {
    if (step == ChangePasswordStep.current) {
      Navigator.of(context).pop();
    } else {
      goTo(ChangePasswordStep.current);
    }
  }

  /// Runs [action] with the loading state and shows the server's reason on failure.
  Future<void> run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    if (isLoading || isSendingCode) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => errorText = e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void finish() {
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(context, 'Password updated.');
  }

  Future<void> submitCurrent() => run(() async {
    await ref
        .read(authServiceProvider)
        .changePassword(
          currentPassword: currentController.text,
          newPassword: newController.text,
        );
    if (mounted) finish();
  });

  Future<void> sendCode() async {
    FocusScope.of(context).unfocus();
    if (isLoading || isSendingCode) return;
    setState(() {
      isSendingCode = true;
      errorText = null;
    });
    try {
      await ref.read(authServiceProvider).forgotPassword(email: widget.email);
      if (!mounted) return;
      codeController.clear();
      goTo(ChangePasswordStep.code);
      AppSnackBar.show(context, 'We emailed a code to ${widget.email}.');
    } on AuthException catch (e) {
      if (mounted) setState(() => errorText = e.message);
    } finally {
      if (mounted) setState(() => isSendingCode = false);
    }
  }

  Future<void> resendCode() async {
    try {
      await ref
          .read(authServiceProvider)
          .resendCode(email: widget.email, purpose: 'reset');
      if (mounted) AppSnackBar.show(context, 'A new code is on its way.');
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    }
  }

  Future<void> submitCode() => run(() async {
    await ref
        .read(authServiceProvider)
        .verifyResetCode(email: widget.email, code: codeController.text.trim());
    if (mounted) goTo(ChangePasswordStep.newPassword);
  });

  Future<void> submitNewPassword() => run(() async {
    await ref
        .read(authServiceProvider)
        .resetPassword(
          email: widget.email,
          code: codeController.text.trim(),
          newPassword: newController.text,
        );
    if (mounted) finish();
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCurrent = step == ChangePasswordStep.current;
    final isCode = step == ChangePasswordStep.code;

    final title = switch (step) {
      ChangePasswordStep.current => 'Change password',
      ChangePasswordStep.code => 'Check your inbox',
      ChangePasswordStep.newPassword => 'Set a new password',
    };
    final message = switch (step) {
      ChangePasswordStep.current =>
        'Enter your current password, then choose a new one.',
      ChangePasswordStep.code =>
        'We sent a 6-digit code to ${widget.email}. Enter it to continue.',
      ChangePasswordStep.newPassword =>
        'Code verified. Choose a new password for ${widget.email}.',
    };

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(title: 'Change password', onBack: back),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTextStyle.headline),
                6.verticalSpace,
                Text(
                  message,
                  style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
                ),
                18.verticalSpace,
                if (isCurrent) ...[
                  AppTextField(
                    controller: currentController,
                    label: 'Current password',
                    hint: 'Current password',
                    variant: AppTextFieldVariant.password,
                    autofillHints: const [AutofillHints.password],
                    validator: AppValidators.required,
                  ),
                  14.verticalSpace,
                ],
                if (isCode)
                  AppTextField(
                    controller: codeController,
                    label: '6-digit code',
                    hint: '••••••',
                    variant: AppTextFieldVariant.otp,
                    validator: AppValidators.otp,
                    onSubmitted: (_) => submitCode(),
                  )
                else
                  AppTextField(
                    controller: newController,
                    label: 'New password',
                    hint: 'At least 8 characters',
                    variant: AppTextFieldVariant.password,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: AppValidators.password,
                    onSubmitted: (_) =>
                        isCurrent ? submitCurrent() : submitNewPassword(),
                  ),
                if (errorText != null) ...[
                  8.verticalSpace,
                  Text(
                    errorText!,
                    style: AppTextStyle.meta.copyWith(color: colors.danger),
                  ),
                ],
                18.verticalSpace,
                AppButton(
                  label: switch (step) {
                    ChangePasswordStep.current => 'Update password',
                    ChangePasswordStep.code => 'Verify code',
                    ChangePasswordStep.newPassword => 'Update password',
                  },
                  isLoading: isLoading,
                  onPressed: isSendingCode
                      ? null
                      : switch (step) {
                          ChangePasswordStep.current => submitCurrent,
                          ChangePasswordStep.code => submitCode,
                          ChangePasswordStep.newPassword => submitNewPassword,
                        },
                ),
                if (isCurrent) ...[
                  12.verticalSpace,
                  AppButton(
                    label: 'Forgot current password?',
                    variant: AppButtonVariant.text,
                    isLoading: isSendingCode,
                    onPressed: isLoading ? null : sendCode,
                  ),
                ],
                if (isCode)
                  AppButton(
                    label: 'Send a new code',
                    variant: AppButtonVariant.text,
                    onPressed: resendCode,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
