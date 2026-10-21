import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.verify`. The 6-digit code is checked
/// by [AuthService.verifyEmail] against the backend, not locally.
///
/// Responsive: displays a split-screen layout with an editorial fitness image
/// on tablet landscape, while maintaining 100% of the mobile experience on phones.
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
      await ref
          .read(authServiceProvider)
          .verifyEmail(email: pending.email, code: codeController.text.trim());
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          final isLandscape =
              constraints.maxWidth >= constraints.maxHeight;
          if (isLandscape || constraints.maxWidth >= 840) {
            return _buildTabletLandscapeLayout(
              context: context,
              colors: colors,
              constraints: constraints,
              pending: pending,
            );
          } else {
            return _buildTabletPortraitLayout(
              context: context,
              colors: colors,
              constraints: constraints,
              pending: pending,
            );
          }
        }

        return _buildMobileLayout(context, colors, pending);
      },
    );
  }

  /// Original mobile layout preserved with zero visual or functional changes.
  Widget _buildMobileLayout(
    BuildContext context,
    AppColors colors,
    PendingAuth pending,
  ) {
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
                    style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
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

  /// Tablet landscape split view: Hero image on left & proportionally scaled OTP form on right.
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
    required PendingAuth pending,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final colW = w / 2;
    final formWidth = (colW * 0.72).clamp(440.0, 750.0);

    final fieldHeight = (h * 0.065).clamp(52.0, 96.0);
    final headlineSize = (h * 0.045).clamp(32.0, 60.0);
    final bodySize = (h * 0.022).clamp(15.5, 32.0);
    final labelFontSize = (h * 0.020).clamp(14.5, 28.0);
    final otpFontSize = (h * 0.028).clamp(20.0, 42.0);
    final buttonFontSize = (h * 0.024).clamp(17.0, 34.0);
    final secondaryFontSize = (h * 0.021).clamp(15.0, 30.0);

    final inputRadius = (h * 0.018).clamp(12.0, 24.0);
    final buttonRadius = (h * 0.022).clamp(16.0, 28.0);

    final gapHeadToBody = (h * 0.016).clamp(10.0, 24.0);
    final gapBodyToField = (h * 0.030).clamp(18.0, 44.0);
    final gapLabelToField = (h * 0.010).clamp(6.0, 16.0);
    final gapFieldToBtn = (h * 0.032).clamp(18.0, 48.0);
    final gapBtnToSecondary = (h * 0.018).clamp(12.0, 28.0);

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Half: Hero image with back button
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/signup_hero.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.15),
                  ),
                  Positioned(
                    top: (h * 0.025).clamp(16.0, 36.0),
                    left: (w * 0.02).clamp(16.0, 36.0),
                    child: AppIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      isOnDark: true,
                      onPressed: () =>
                          ref.read(appFlowProvider.notifier).showSignup(),
                    ),
                  ),
                ],
              ),
            ),
            // Right Half: Form matching tablet styling
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: (w * 0.03).clamp(24.0, 60.0),
                    vertical: (h * 0.03).clamp(20.0, 48.0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: formWidth),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Check your inbox',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: headlineSize,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.8,
                              color: colors.ink,
                            ),
                          ),
                          SizedBox(height: gapHeadToBody),
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.figtree(
                                fontSize: bodySize,
                                fontWeight: FontWeight.w400,
                                height: 1.55,
                                color: colors.ink2,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'We sent a 6-digit code to ',
                                ),
                                TextSpan(
                                  text: pending.email,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colors.ink,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          SizedBox(height: gapBodyToField),
                          Text(
                            '6-digit code',
                            style: GoogleFonts.figtree(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          SizedBox(height: gapLabelToField),
                          TextFormField(
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            autofillHints: const [AutofillHints.oneTimeCode],
                            validator: AppValidators.otp,
                            onChanged: (_) {
                              if (codeError != null) {
                                setState(() => codeError = null);
                              }
                            },
                            onFieldSubmitted: (_) => submit(pending),
                            style: GoogleFonts.figtree(
                              fontSize: otpFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: otpFontSize,
                                letterSpacing: 8,
                                color: colors.ink3,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: (fieldHeight * 0.35).clamp(16.0, 32.0),
                                vertical: (fieldHeight * 0.28).clamp(12.0, 26.0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.accent,
                                  width: 1.8,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          if (codeError != null) ...[
                            SizedBox(height: (h * 0.010).clamp(6.0, 16.0)),
                            Text(
                              codeError!,
                              style: GoogleFonts.figtree(
                                fontSize: (h * 0.018).clamp(13.0, 24.0),
                                color: colors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          SizedBox(height: gapFieldToBtn),
                          // Primary Verify and Continue Button
                          Material(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(buttonRadius),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: isLoading ? null : () => submit(pending),
                              child: Container(
                                height: fieldHeight,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: isLoading
                                    ? SizedBox(
                                        width: (h * 0.026).clamp(18.0, 36.0),
                                        height: (h * 0.026).clamp(18.0, 36.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colors.accentInk,
                                        ),
                                      )
                                    : Text(
                                        'Verify and continue',
                                        style: GoogleFonts.figtree(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: colors.accentInk,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapBtnToSecondary),
                          // Resend code link
                          Center(
                            child: InkWell(
                              onTap: isResending ? null : () => resend(pending),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: isResending
                                    ? SizedBox(
                                        width: (h * 0.022).clamp(16.0, 28.0),
                                        height: (h * 0.022).clamp(16.0, 28.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.accent,
                                        ),
                                      )
                                    : Text(
                                        'Send a new code',
                                        style: GoogleFonts.figtree(
                                          fontSize: secondaryFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: colors.accent,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet portrait layout: Centered form with ergonomic max width.
  Widget _buildTabletPortraitLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
    required PendingAuth pending,
  }) {
    final formMaxWidth = (constraints.maxWidth * 0.75).clamp(380.0, 520.0);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Verify email',
        onBack: () => ref.read(appFlowProvider.notifier).showSignup(),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Check your inbox', style: AppTextStyle.headline),
                    8.verticalSpace,
                    Text.rich(
                      TextSpan(
                        style:
                            AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
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
                    24.verticalSpace,
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
                        style:
                            AppTextStyle.meta.copyWith(color: colors.danger),
                      ),
                    ],
                    24.verticalSpace,
                    AppButton(
                      label: 'Verify and continue',
                      onPressed: () => submit(pending),
                      isLoading: isLoading,
                    ),
                    12.verticalSpace,
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
        ),
      ),
    );
  }
}
