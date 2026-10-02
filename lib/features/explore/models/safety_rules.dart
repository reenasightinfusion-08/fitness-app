import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';

/// What "Safe for me" hides, from the answers given during setup. Mirrors the
/// server's plan rules (`backend/utils/dailyPlan.js`), so Explore and the daily
/// plan agree on what is safe.
class SafetyRules {
  const SafetyRules({
    this.noFloor = false,
    this.noKneel = false,
    this.onlyBeginner = false,
    this.avoidPoses = const {},
    this.avoidAreas = const {},
    this.avoidStretchIds = const {},
  });

  factory SafetyRules.fromProfile(
    OnboardingProfile profile,
    Set<String> hurtStretchIds,
  ) {
    bool hurts(String key) {
      final severity = profile.injurySeverity[key];
      return severity == InjurySeverity.moderate ||
          severity == InjurySeverity.serious;
    }

    return SafetyRules(
      noFloor: profile.noFloor,
      noKneel: profile.noKneel || hurts('knee'),
      onlyBeginner: profile.hadRecentSurgery,
      avoidPoses: profile.isPregnant ? _pregnancyAvoid : const {},
      avoidAreas: {
        for (final entry in _injuryAreas.entries)
          if (hurts(entry.key)) ...entry.value,
      },
      avoidStretchIds: hurtStretchIds,
    );
  }

  final bool noFloor;
  final bool noKneel;
  final bool onlyBeginner;
  final Set<String> avoidPoses;
  final Set<String> avoidAreas;
  final Set<String> avoidStretchIds;

  /// Nothing lying on the front, no deep twists.
  static const _pregnancyAvoid = {
    'cobra',
    'supinetwist',
    'seatedtwist',
    'chairtwist',
    'torsotwist',
    'thread',
  };

  /// Body areas a moderate or serious injury rules out.
  static const _injuryAreas = {
    'back': ['lowerback'],
    'neck': ['neck'],
    'shoulder': ['shoulders'],
    'wrist': ['wrists'],
    'hip': ['hips'],
    'knee': ['quads'],
  };

  bool allowsStretch(StretchModel stretch) =>
      !(noFloor && stretch.position == StretchPosition.floor) &&
      !(noKneel && stretch.isKneeling) &&
      !(onlyBeginner && stretch.level != RoutineLevel.beginner) &&
      !avoidPoses.contains(stretch.poseKey) &&
      !stretch.areas.any(avoidAreas.contains) &&
      !avoidStretchIds.contains(stretch.id);

  /// A stretch inside a routine. Demo stretches have no saved details, so only
  /// what a preview knows (where it is done) can be checked for those.
  bool allowsPreview(StretchPreview preview) {
    final model = preview.model;
    if (model != null) return allowsStretch(model);
    return !(noFloor && preview.position == StretchPosition.floor);
  }

  bool allowsRoutine(RoutineSummary routine) =>
      !(onlyBeginner && routine.level != RoutineLevel.beginner) &&
      routine.stretches.every(allowsPreview);
}
