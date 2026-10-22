import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/auth/widgets/auth_legal_notice.dart';
import 'package:fitness_app/features/auth/widgets/auth_social_buttons.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.signup`. Email/password are local
/// `TextEditingController`s — form input is UI-only state and doesn't
/// belong in a provider. Submits to [AuthService.signup], starts a
/// [PendingAuthController] for the verify-email step, and hands off to
/// [AppFlowController.showVerifyEmail].
///
/// Responsive: displays a split-screen layout with an editorial fitness image
/// (signup_hero.jpg) on tablet landscape, while maintaining 100% of the mobile experience on phones.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends ConsumerState<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hasSubmitted = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
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
      ref.invalidate(onboardingProfileProvider);
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

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading || isLoading) return;
    setState(() => isGoogleLoading = true);
    try {
      final signedIn = await ref
          .read(authServiceProvider)
          .loginWithGoogle(isSignup: true);
      if (signedIn && mounted) {
        await ref.read(appFlowProvider.notifier).enterAfterSignIn();
      }
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            );
          } else {
            return _buildTabletPortraitLayout(
              context: context,
              colors: colors,
              constraints: constraints,
            );
          }
        }

        return _buildMobileLayout(context, colors);
      },
    );
  }

  /// Original mobile layout preserved with zero visual or functional changes.
  Widget _buildMobileLayout(BuildContext context, AppColors colors) {
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
                const AuthSocialButtons(isSignup: true),
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
                16.verticalSpace,
                const AuthLegalNotice(),
                20.verticalSpace,
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

  /// Tablet landscape split view: Left signup_hero.jpg & right form matching mockup.
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final colW = w / 2;
    final formWidth = (colW * 0.75).clamp(400.0, 480.0);

    // Balanced tablet sizing
    const fieldHeight = 50.0;
    const labelFontSize = 14.0;
    const inputFontSize = 15.0;
    const googleFontSize = 15.0;
    const googleIconSize = 20.0;
    const dividerFontSize = 13.0;
    const buttonFontSize = 16.0;
    const linkFontSize = 14.0;
    const noticeFontSize = 13.0;

    const inputRadius = 14.0;
    const buttonRadius = 14.0;

    const gapSocialToDiv = 16.0;
    const gapDivToEmail = 16.0;
    const gapLabelToField = 6.0;
    const gapEmailToPass = 16.0;
    const gapPassToBtn = 20.0;
    const gapBtnToNotice = 12.0;
    const gapNoticeToLink = 16.0;

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Half: Hero image (signup_hero.jpg) with back button
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
                          ref.read(appFlowProvider.notifier).showWelcome(),
                    ),
                  ),
                ],
              ),
            ),
            // Right Half: Proportionally sized form matching mockup
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
                          // Continue with Google Button
                          Material(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(buttonRadius),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: signInWithGoogle,
                              child: Container(
                                height: fieldHeight,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(buttonRadius),
                                  border: Border.all(
                                    color: colors.line.withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                ),
                                child: isGoogleLoading
                                    ? Center(
                                        child: SizedBox(
                                          width: googleIconSize,
                                          height: googleIconSize,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: colors.accent,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/google_g.png',
                                            width: googleIconSize,
                                            height: googleIconSize,
                                          ),
                                          SizedBox(
                                            width: (h * 0.015).clamp(8.0, 20.0),
                                          ),
                                          Text(
                                            'Continue with Google',
                                            style: GoogleFonts.figtree(
                                              fontSize: googleFontSize,
                                              fontWeight: FontWeight.w700,
                                              color: colors.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapSocialToDiv),
                          // Divider "or continue"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: colors.line,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (w * 0.015).clamp(10.0, 24.0),
                                ),
                                child: Text(
                                  'or continue',
                                  style: GoogleFonts.figtree(
                                    fontSize: dividerFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: colors.ink3,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: colors.line,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: gapDivToEmail),
                          // Email Field Label
                          Text(
                            'Email',
                            style: GoogleFonts.figtree(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          SizedBox(height: gapLabelToField),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: AppValidators.email,
                            autovalidateMode: hasSubmitted
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            style: GoogleFonts.figtree(
                              fontSize: inputFontSize,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'you@example.com',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: inputFontSize,
                                color: colors.ink3,
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    (fieldHeight * 0.35).clamp(16.0, 32.0),
                                vertical: (fieldHeight * 0.28).clamp(12.0, 26.0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.accent,
                                  width: 1.8,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapEmailToPass),
                          // Password Field Label
                          Text(
                            'Password',
                            style: GoogleFonts.figtree(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          SizedBox(height: gapLabelToField),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: AppValidators.password,
                            onFieldSubmitted: (_) => submit(),
                            autovalidateMode: hasSubmitted
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            style: GoogleFonts.figtree(
                              fontSize: inputFontSize,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'At least 8 characters',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: inputFontSize,
                                color: colors.ink3,
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    (fieldHeight * 0.35).clamp(16.0, 32.0),
                                vertical: (fieldHeight * 0.28).clamp(12.0, 26.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: (h * 0.026).clamp(18.0, 36.0),
                                  color: colors.ink2,
                                ),
                                onPressed: () => setState(
                                  () => isPasswordVisible = !isPasswordVisible,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.line,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.accent,
                                  width: 1.8,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(inputRadius),
                                borderSide: BorderSide(
                                  color: colors.danger,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapPassToBtn),
                          // Primary Create Account Button
                          Material(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(buttonRadius),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: isLoading ? null : submit,
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
                                        'Create account',
                                        style: GoogleFonts.figtree(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: colors.accentInk,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapBtnToNotice),
                          AuthLegalNotice(fontSize: noticeFontSize),
                          SizedBox(height: gapNoticeToLink),
                          // Already have an account? Log in link
                          Center(
                            child: InkWell(
                              onTap: () => ref
                                  .read(appFlowProvider.notifier)
                                  .showLogin(),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.figtree(
                                      fontSize: linkFontSize,
                                      color: colors.ink2,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Already have an account? ',
                                      ),
                                      TextSpan(
                                        text: 'Log in',
                                        style: TextStyle(
                                          color: colors.accent,
                                          fontWeight: FontWeight.w700,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ],
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
  }) {
    final formMaxWidth = (constraints.maxWidth * 0.75).clamp(380.0, 520.0);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Create account',
        onBack: () => ref.read(appFlowProvider.notifier).showWelcome(),
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
                    const AuthSocialButtons(
                      isSignup: true,
                      dividerText: 'or continue',
                    ),
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
                    16.verticalSpace,
                    AuthLegalNotice(
                      fontSize: (constraints.maxWidth * 0.022).clamp(13.0, 18.0),
                    ),
                    20.verticalSpace,
                    AppInlineLink(
                      prefix: 'Already have an account?',
                      linkText: 'Log in',
                      onTap: () =>
                          ref.read(appFlowProvider.notifier).showLogin(),
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
