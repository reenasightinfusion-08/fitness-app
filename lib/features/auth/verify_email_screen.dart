import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.verify`. The 6-digit code is checked
/// by [AuthService.verifyEmail] against the backend, not locally.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => VerifyEmailScreenState();
}

class VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  String? codeError;
  bool isLoading = false;
  bool isResending = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> submit(PendingAuth pending) async {
    FocusScope.of(context).unfocus();
    if (isLoading) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isLoading = true;
      codeError = null;
    });
    try {
      await ref.read(authServiceProvider).verifyEmail(
        email: pending.email,
        code: codeController.text.trim(),
      );
      if (!mounted) return;
      ref.read(pendingAuthProvider.notifier).clear();
      ref.read(appFlowProvider.notifier).showOnboarding();
    } on AuthException catch (e) {
      setState(() => codeError = e.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resend(PendingAuth pending) async {
    if (isResending) return;
    setState(() => isResending = true);
    try {
      await ref
          .read(authServiceProvider)
          .resendCode(email: pending.email, purpose: 'verify');
      if (mounted) {
        setState(() => codeError = null);
        AppSnackBar.show(context, 'New code sent.');
      }
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = ref.watch(pendingAuthProvider);

    // No pending signup to verify — back out rather than show a dead form.
    if (pending == null) {
      return Scaffold(
        backgroundColor: colors.ground,
        appBar: AppTopBar(
          title: 'Verify email',
          onBack: () => ref.read(appFlowProvider.notifier).showSignup(),
        ),
        body: Padding(
          padding: AppInsets.page,
          child: AppEmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'Nothing to verify yet',
            message: 'Start by creating an account.',
            actionLabel: 'Create account',
            onAction: () => ref.read(appFlowProvider.notifier).showSignup(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Verify email',
        onBack: () => ref.read(appFlowProvider.notifier).showSignup(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Check your inbox', style: AppTextStyle.headline),
                6.verticalSpace,
                Text.rich(
                  TextSpan(
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: pending.email,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                18.verticalSpace,
                AppTextField(
                  controller: codeController,
                  label: '6-digit code',
                  hint: '••••••',
                  variant: AppTextFieldVariant.otp,
                  validator: AppValidators.otp,
                  onChanged: (_) {
                    if (codeError != null) setState(() => codeError = null);
                  },
                  onSubmitted: (_) => submit(pending),
                ),
                if (codeError != null) ...[
                  6.verticalSpace,
                  Text(
                    codeError!,
                    style: AppTextStyle.meta.copyWith(color: colors.danger),
                  ),
                ],
                18.verticalSpace,
                AppButton(
                  label: 'Verify and continue',
                  onPressed: () => submit(pending),
                  isLoading: isLoading,
                ),
                10.verticalSpace,
                AppButton(
                  label: 'Send a new code',
                  variant: AppButtonVariant.text,
                  onPressed: () => resend(pending),
                  isLoading: isResending,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
