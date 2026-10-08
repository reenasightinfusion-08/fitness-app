import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class OnboardingSetupScreenState
    extends ConsumerState<OnboardingSetupScreen> {
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
      if (mounted) AppSnackBar.showError(context, "Couldn't save: ${e.message}");
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
}
