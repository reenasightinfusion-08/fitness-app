import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Matches the prototype's `screens.verify`. There's no real mail here —
/// same as the mock, the "sent" code is shown on screen in a demo note,
/// and matching it against [PendingAuthController]'s state is the whole
/// check.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => VerifyEmailScreenState();
}

class VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  String? codeError;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void submit(PendingAuth pending) {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (codeController.text.trim() != pending.code) {
      setState(
        () => codeError = "That code doesn't match. Check the latest code "
            'and try again.',
      );
      return;
    }
    ref.read(pendingAuthProvider.notifier).clear();
    ref.read(appFlowProvider.notifier).showOnboarding();
  }

  void resend() {
    ref.read(pendingAuthProvider.notifier).resend();
    setState(() => codeError = null);
    AppSnackBar.show(context, 'New code sent.');
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
                AppNote(
                  tone: AppTone.warm,
                  message:
                      'Prototype: no email is actually sent. Your code is '
                      '${pending.code}',
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
                ),
                10.verticalSpace,
                AppButton(
                  label: 'Send a new code',
                  variant: AppButtonVariant.text,
                  onPressed: resend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
