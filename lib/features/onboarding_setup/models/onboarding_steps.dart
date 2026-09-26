import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';

/// One of the 10 steps in [onboardingSteps], mirroring an entry in the
/// prototype's `OB` array.
class OnboardingStepDef {
  const OnboardingStepDef({
    required this.title,
    this.why,
    this.skippable = false,
    this.validate,
  });

  final String title;
  final String? why;

  /// True for steps the prototype marks `skip:true` — a "Skip" action
  /// appears in the top bar alongside Continue.
  final bool skippable;

  /// Null means "always valid" (Continue is never disabled).
  final bool Function(OnboardingProfile profile)? validate;
}

/// The 10-step flow, in order — index 0 is `screens.ob({step: 0})`,
/// index 9 the last ("Build my plan") step.
final List<OnboardingStepDef> onboardingSteps = [
  // 0 · basic
  OnboardingStepDef(
    title: 'What should we call you?',
    why:
        'Your name personalises the voice cues. Age helps us pick a '
        'kinder pace if you need one.',
    validate: (profile) => profile.name.trim().isNotEmpty,
  ),
  // 1 · body
  const OnboardingStepDef(
    title: 'Height and weight',
    why:
        'Optional. Used only to suggest gentler variations and, if you '
        "turn it on, estimate calories. We never show BMI.",
    skippable: true,
  ),
  // 2 · life
  OnboardingStepDef(
    title: 'What does a normal day look like?',
    why:
        'Desk days tighten hips, chest and neck; training days need '
        'recovery. We plan around yours.',
    validate: (profile) => profile.lifestyle != null,
  ),
  // 3 · goal
  OnboardingStepDef(
    title: 'What do you want from stretching?',
    why: 'Pick up to two. This decides which body areas get the most time.',
    validate: (profile) => profile.goals.isNotEmpty,
  ),
  // 4 · pain
  const OnboardingStepDef(
    title: 'Where do you feel tight or sore?',
    why: 'Tap the areas that need it. These get extra time in every plan.',
    skippable: true,
  ),
  // 5 · inj
  const OnboardingStepDef(
    title: 'Anything we should work around?',
    why:
        'We remove stretches that could aggravate these and swap in '
        'safer versions.',
    skippable: true,
  ),
  // 6 · equip
  OnboardingStepDef(
    title: 'What do you have at home?',
    why: 'We only suggest stretches you can actually do with what you have.',
    validate: (profile) =>
        profile.equipment.isNotEmpty || profile.equipmentNone,
  ),
  // 7 · flex
  OnboardingStepDef(
    title: 'Quick flexibility check',
    why:
        'Three honest answers set your starting level. Retake it anytime '
        'from Progress.',
    validate: (profile) =>
        profile.flexAnswers.every((answer) => answer != null),
  ),
  // 8 · time
  const OnboardingStepDef(
    title: 'How much time do you have?',
    why:
        'Your daily plan fits this exactly, including the time it takes '
        'to change position.',
  ),
  // 9 · safety
  OnboardingStepDef(
    title: 'Before you start',
    validate: (profile) => profile.safetyAcknowledged,
  ),
];
