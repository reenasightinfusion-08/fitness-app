import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
///
/// Responsive: displays a split-screen layout with an editorial fitness image
/// on tablet landscape matching the tablet mockup, while maintaining 100% of
/// the mobile experience on phones.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
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
    setState(() => hasSubmitted = true);
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .login(
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

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading || isLoading) return;
    setState(() => isGoogleLoading = true);
    try {
      final signedIn = await ref
          .read(authServiceProvider)
          .loginWithGoogle(isSignup: false);
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

  /// Tablet landscape split view: Exactly matching the user's tablet mockup.
  /// Scaled proportionally to viewport height so inputs, typography, and buttons
  /// are bold and comfortable on any tablet resolution.
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final colW = w / 2;
    // Form occupies ~72% of right column width
    final formWidth = (colW * 0.72).clamp(440.0, 750.0);

    // Dynamic proportional sizing
    final fieldHeight = (h * 0.065).clamp(52.0, 96.0);
    final labelFontSize = (h * 0.020).clamp(14.5, 28.0);
    final inputFontSize = (h * 0.022).clamp(15.5, 32.0);
    final googleFontSize = (h * 0.022).clamp(16.0, 32.0);
    final googleIconSize = (h * 0.030).clamp(20.0, 44.0);
    final dividerFontSize = (h * 0.018).clamp(13.0, 24.0);
    final forgotFontSize = (h * 0.019).clamp(14.0, 26.0);
    final buttonFontSize = (h * 0.024).clamp(17.0, 34.0);
    final linkFontSize = (h * 0.020).clamp(14.5, 28.0);

    final inputRadius = (h * 0.018).clamp(12.0, 24.0);
    final buttonRadius = (h * 0.022).clamp(16.0, 28.0);

    final gapSocialToDiv = (h * 0.024).clamp(14.0, 36.0);
    final gapDivToEmail = (h * 0.024).clamp(14.0, 36.0);
    final gapLabelToField = (h * 0.010).clamp(6.0, 16.0);
    final gapEmailToPass = (h * 0.020).clamp(12.0, 32.0);
    final gapPassToForgot = (h * 0.012).clamp(6.0, 18.0);
    final gapForgotToBtn = (h * 0.032).clamp(18.0, 48.0);
    final gapBtnToLink = (h * 0.024).clamp(14.0, 36.0);

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
                    'assets/images/login_hero.jpg',
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
                            autofillHints: const [AutofillHints.password],
                            validator: AppValidators.required,
                            onFieldSubmitted: (_) => submit(),
                            autovalidateMode: hasSubmitted
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            style: GoogleFonts.figtree(
                              fontSize: inputFontSize,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Your password',
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
                          SizedBox(height: gapPassToForgot),
                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => ref
                                  .read(appFlowProvider.notifier)
                                  .showForgotPassword(),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.figtree(
                                    fontSize: forgotFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapForgotToBtn),
                          // Primary Log in Button
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
                                        'Log in',
                                        style: GoogleFonts.figtree(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: colors.accentInk,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapBtnToLink),
                          // New here? Create an account link
                          Center(
                            child: InkWell(
                              onTap: () => ref
                                  .read(appFlowProvider.notifier)
                                  .showSignup(),
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
                                      const TextSpan(text: 'New here? '),
                                      TextSpan(
                                        text: 'Create an account',
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
        title: 'Log in',
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
                    const AuthSocialButtons(dividerText: 'or continue'),
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
                        onPressed: () => ref
                            .read(appFlowProvider.notifier)
                            .showForgotPassword(),
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
                      onTap: () =>
                          ref.read(appFlowProvider.notifier).showSignup(),
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
