import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_steps.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/basic_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/body_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/equipment_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/flexibility_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/goals_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/injuries_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/lifestyle_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/pain_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/safety_step.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/time_step.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/services/auth_service.dart';

const int _bodyStepIndex = 1;

/// The 10-step profile-setup wizard, matching the prototype's `screens.ob`.
/// A single screen swaps its step content by index rather than pushing a
/// new route per step, so the top bar's progress bar and Continue button
/// stay put while the body animates between steps.
///
/// Passing [editStepIndex] opens directly on that one step in "edit"
/// mode — matching the prototype's `screens.ob({step, edit: true})`,
/// reached by tapping a row on [EditProfileScreen]: a plain title
/// instead of the progress bar, no Skip action, and a "Save" button that
/// pops back to Edit profile instead of advancing to the next step.
class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({super.key, this.editStepIndex});

  final int? editStepIndex;

  @override
  ConsumerState<OnboardingSetupScreen> createState() =>
      OnboardingSetupScreenState();
}

class OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  late int currentStep = widget.editStepIndex ?? 0;

  bool get isEditMode => widget.editStepIndex != null;
  bool get isLastStep =>
      !isEditMode && currentStep == onboardingSteps.length - 1;

  void goBack() {
    if (isEditMode || currentStep == 0) return;
    setState(() => currentStep -= 1);
  }

  bool isSyncing = false;

  void skip() {
    if (currentStep == _bodyStepIndex) {
      ref.read(onboardingProfileProvider.notifier).resetHeightWeight();
    }
    advance();
  }

  Future<void> advance() async {
    if (isEditMode) {
      await _syncProfile();
      ref.invalidate(todaysPlanProvider);
      ref.invalidate(planOverviewProvider);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (isLastStep) {
      await _syncProfile(markComplete: true);
      final profile = ref.read(onboardingProfileProvider);
      if (profile.reminderOn) {
        ref
            .read(remindersProvider.notifier)
            .addFromOnboarding(profile.reminderTime);
      }
      if (mounted) ref.read(appFlowProvider.notifier).showPlanReady();
      return;
    }
    setState(() => currentStep += 1);
  }

  /// Pushes the wizard's current answers to `PATCH /api/users/me`. Never
  /// blocks navigation on failure — the profile still lives in
  /// [onboardingProfileProvider] locally, so a flaky connection here just
  /// means the next successful sync (or a manual retry) catches it up.
  Future<void> _syncProfile({bool markComplete = false}) async {
    if (isSyncing) return;
    setState(() => isSyncing = true);
    try {
      final profile = ref.read(onboardingProfileProvider);
      await ref
          .read(authServiceProvider)
          .updateMe(profile.toUserUpdate(markComplete: markComplete));
    } on AuthException catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, "Couldn't save: ${e.message}");
      }
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  Widget stepContent(int index) => switch (index) {
    0 => const BasicStep(),
    1 => const BodyStep(),
    2 => const LifestyleStep(),
    3 => const GoalsStep(),
    4 => const PainStep(),
    5 => const InjuriesStep(),
    6 => const EquipmentStep(),
    7 => const FlexibilityStep(),
    8 => const TimeStep(),
    _ => const SafetyStep(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final step = onboardingSteps[currentStep];
    final isValid = step.validate?.call(profile) ?? true;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          final isLandscape = constraints.maxWidth >= constraints.maxHeight;
          if (isLandscape || constraints.maxWidth >= 840) {
            return _buildTabletLandscapeLayout(
              context: context,
              colors: colors,
              constraints: constraints,
              step: step,
              isValid: isValid,
            );
          } else {
            return _buildTabletPortraitLayout(
              context: context,
              colors: colors,
              constraints: constraints,
              step: step,
              isValid: isValid,
            );
          }
        }

        return _buildMobileLayout(
          context: context,
          colors: colors,
          step: step,
          isValid: isValid,
        );
      },
    );
  }

  /// Original mobile layout preserved with zero visual or functional changes.
  Widget _buildMobileLayout({
    required BuildContext context,
    required AppColors colors,
    required OnboardingStepDef step,
    required bool isValid,
  }) {
    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: isEditMode ? 'Edit profile' : null,
        onBack: isEditMode
            ? () => Navigator.of(context).pop()
            : (currentStep == 0 ? null : goBack),
        center: isEditMode
            ? null
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: AppProgressBar(
                  value: (currentStep + 1) / onboardingSteps.length,
                ),
              ),
        trailing: !isEditMode && step.skippable
            ? AppButton(
                label: 'Skip',
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                isExpanded: false,
                onPressed: skip,
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppInsets.page,
                child: Column(
                  key: ValueKey(currentStep),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isEditMode) ...[
                      Text(
                        'Step ${currentStep + 1} of ${onboardingSteps.length}',
                        style: AppTextStyle.eyebrow.copyWith(
                          color: colors.accent,
                        ),
                      ),
                      8.verticalSpace,
                    ],
                    Text(step.title, style: AppTextStyle.titleLarge),
                    if (step.why != null) ...[
                      6.verticalSpace,
                      Text(
                        step.why!,
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: colors.ink2,
                        ),
                      ),
                    ],
                    22.verticalSpace,
                    stepContent(currentStep),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
              child: AppButton(
                label: isEditMode
                    ? 'Save'
                    : (isLastStep ? 'Build my plan' : 'Continue'),
                onPressed: isValid && !isSyncing ? advance : null,
                isLoading: isSyncing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet landscape split view: Hero image on left & proportionally scaled step form on right.
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
    required OnboardingStepDef step,
    required bool isValid,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final colW = w / 2;
    // Form occupies generous width in right column
    final formWidth = (colW * 0.88).clamp(500.0, 960.0);

    // Bold, comfortable typography matching tablet viewport
    final titleSize = (h * 0.058).clamp(40.0, 64.0);
    final subtitleSize = (h * 0.028).clamp(19.0, 30.0);
    final eyebrowSize = (h * 0.024).clamp(17.0, 26.0);
    final buttonHeight = (h * 0.075).clamp(64.0, 88.0);

    final canGoBack = (!isEditMode && currentStep > 0) || isEditMode;

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Row(
          children: [
            // Left column: Editorial hero card
            Expanded(
              child: Padding(
                padding: EdgeInsets.all((h * 0.024).clamp(16.0, 32.0)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/onboarding_hero.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      // Soft gradient overlay at bottom
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Floating circular back button on image card
                      if (canGoBack)
                        Positioned(
                          top: 20.0,
                          left: 20.0,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: isEditMode
                                  ? () => Navigator.of(context).pop()
                                  : goBack,
                              child: Container(
                                width: 44.0,
                                height: 44.0,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: colors.ink,
                                  size: 22.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Bottom inspirational floating card
                      Positioned(
                        left: 24.0,
                        right: 24.0,
                        bottom: 24.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 18.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(22.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: (h * 0.016).clamp(14.0, 20.0),
                                      vertical: (h * 0.008).clamp(6.0, 10.0),
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.accent.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      isEditMode
                                          ? 'EDIT PROFILE'
                                          : 'STEP ${currentStep + 1} OF ${onboardingSteps.length}',
                                      style: GoogleFonts.figtree(
                                        fontSize: (h * 0.020).clamp(15.0, 22.0),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isEditMode)
                                    Text(
                                      '${((currentStep + 1) / onboardingSteps.length * 100).round()}% done',
                                      style: GoogleFonts.figtree(
                                        fontSize: (h * 0.022).clamp(16.5, 24.0),
                                        fontWeight: FontWeight.w700,
                                        color: colors.ink2,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: (h * 0.014).clamp(10.0, 16.0)),
                              Text(
                                isEditMode
                                    ? 'Updating your personal fitness preferences.'
                                    : 'Building your personalized daily flexibility routine.',
                                style: GoogleFonts.figtree(
                                  fontSize: (h * 0.026).clamp(19.0, 28.0),
                                  fontWeight: FontWeight.w600,
                                  color: colors.ink,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right column: Form and progress
            Expanded(
              child: Column(
                children: [
                  // Top progress bar header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (colW - formWidth) / 2 > 24
                          ? (colW - formWidth) / 2
                          : 24.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      children: [
                        if (canGoBack) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: colors.ink,
                            onPressed: isEditMode
                                ? () => Navigator.of(context).pop()
                                : goBack,
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        if (isEditMode)
                          Text(
                            'Edit profile',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          )
                        else
                          Expanded(
                            child: AppProgressBar(
                              value: (currentStep + 1) / onboardingSteps.length,
                              height: 8,
                            ),
                          ),
                        if (!isEditMode && step.skippable) ...[
                          const SizedBox(width: 16.0),
                          AppButton(
                            label: 'Skip',
                            variant: AppButtonVariant.text,
                            size: AppButtonSize.small,
                            isExpanded: false,
                            onPressed: skip,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Step scrollable content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: formWidth),
                          child: Column(
                            key: ValueKey(currentStep),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isEditMode) ...[
                                Text(
                                  'Step ${currentStep + 1} of ${onboardingSteps.length}',
                                  style: GoogleFonts.figtree(
                                    fontSize: eyebrowSize,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                              ],
                              Text(
                                step.title,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: colors.ink,
                                  height: 1.15,
                                ),
                              ),
                              if (step.why != null) ...[
                                const SizedBox(height: 12.0),
                                Text(
                                  step.why!,
                                  style: GoogleFonts.figtree(
                                    fontSize: subtitleSize,
                                    fontWeight: FontWeight.w400,
                                    color: colors.ink2,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32.0),
                              stepContent(currentStep),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom continue button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: formWidth),
                      child: SizedBox(
                        height: buttonHeight,
                        child: AppButton(
                          label: isEditMode
                              ? 'Save'
                              : (isLastStep ? 'Build my plan' : 'Continue'),
                          onPressed: isValid && !isSyncing ? advance : null,
                          isLoading: isSyncing,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet portrait layout: Centered ergonomic wizard container.
  Widget _buildTabletPortraitLayout({
    required BuildContext context,
    required AppColors colors,
    required BoxConstraints constraints,
    required OnboardingStepDef step,
    required bool isValid,
  }) {
    final h = constraints.maxHeight;
    final formWidth = (constraints.maxWidth * 0.88).clamp(520.0, 750.0);
    final titleSize = (h * 0.046).clamp(36.0, 52.0);
    final subtitleSize = (h * 0.024).clamp(18.5, 26.0);
    final eyebrowSize = (h * 0.020).clamp(16.0, 22.0);
    final buttonHeight = (h * 0.068).clamp(60.0, 78.0);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: isEditMode ? 'Edit profile' : null,
        onBack: isEditMode
            ? () => Navigator.of(context).pop()
            : (currentStep == 0 ? null : goBack),
        center: isEditMode
            ? null
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AppProgressBar(
                      value: (currentStep + 1) / onboardingSteps.length,
                      height: 8,
                    ),
                  ),
                ),
              ),
        trailing: !isEditMode && step.skippable
            ? AppButton(
                label: 'Skip',
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                isExpanded: false,
                onPressed: skip,
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: formWidth),
                    child: Column(
                      key: ValueKey(currentStep),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isEditMode) ...[
                          Text(
                            'Step ${currentStep + 1} of ${onboardingSteps.length}',
                            style: GoogleFonts.figtree(
                              fontSize: eyebrowSize,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                        ],
                        Text(
                          step.title,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                            height: 1.2,
                          ),
                        ),
                        if (step.why != null) ...[
                          const SizedBox(height: 10.0),
                          Text(
                            step.why!,
                            style: GoogleFonts.figtree(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w400,
                              color: colors.ink2,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32.0),
                        stepContent(currentStep),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: SizedBox(
                  height: buttonHeight,
                  child: AppButton(
                    label: isEditMode
                        ? 'Save'
                        : (isLastStep ? 'Build my plan' : 'Continue'),
                    onPressed: isValid && !isSyncing ? advance : null,
                    isLoading: isSyncing,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
