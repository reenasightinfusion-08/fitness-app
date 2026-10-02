import 'package:flutter/foundation.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';

/// A filterable body area, as shown in the area-chip row — mirrors the
/// prototype's `FILTER_AREAS` + `AREA_LABEL`.
@immutable
class ExploreArea {
  const ExploreArea(this.key, this.label);

  final String key;
  final String label;
}

/// The time-filter chips. Each is a range of exact seconds with no overlap
/// between neighbours: a routine is over [overSeconds] and at most [maxSeconds],
/// so 5:50 is "5 to 10" and exactly 10:00 is still "5 to 10".
enum ExploreTimeFilter {
  any('Any length'),
  upTo5('5 min or less', maxSeconds: 5 * 60),
  from5To10('5 to 10 min', overSeconds: 5 * 60, maxSeconds: 10 * 60),
  from10To15('10 to 15 min', overSeconds: 10 * 60, maxSeconds: 15 * 60),
  over15('15+ min', overSeconds: 15 * 60);

  const ExploreTimeFilter(this.label, {this.overSeconds, this.maxSeconds});

  final String label;

  /// Exclusive lower bound.
  final int? overSeconds;

  /// Inclusive upper bound.
  final int? maxSeconds;

  bool matches(int seconds) {
    if (overSeconds != null && seconds <= overSeconds!) return false;
    if (maxSeconds != null && seconds > maxSeconds!) return false;
    return true;
  }
}

/// One entry in the stretch library — mirrors `STRETCHES`.
@immutable
class ExploreStretch {
  const ExploreStretch({
    required this.name,
    required this.pose,
    required this.areas,
  });

  final String name;
  final StretchPose pose;

  /// [ExploreArea.key]s this stretch targets.
  final List<String> areas;
}

/// One entry in the routine list — mirrors `getRoutine()` as rendered by
/// `routineCard()`: a thumbnail, a name, a "12 min · 6 stretches ·
/// Standing → Floor" meta line, and an optional Premium lock.
@immutable
class ExploreRoutine {
  const ExploreRoutine({
    required this.name,
    required this.minutes,
    required this.stretchCount,
    required this.sequence,
    required this.previewPose,
    required this.areas,
    this.isPremium = false,
  });

  final String name;
  final int minutes;
  final int stretchCount;

  /// e.g. "Standing → Seated → Floor" — the prototype's `seqLine()`.
  final String sequence;
  final StretchPose previewPose;
  final List<String> areas;
  final bool isPremium;

  String get meta => '$minutes min · $stretchCount stretches · $sequence';
}

/// Builds the full [RoutineSummary] the routine detail / player screens
/// need, since the Explore list only keeps a lightweight preview. Pulls
/// matching entries from the stretch library rather than duplicating a
/// full stretch list per routine.
extension ExploreRoutineDetail on ExploreRoutine {
  RoutineSummary toRoutineSummary() {
    final matches = ExploreDemoData.stretches
        .where((s) => s.areas.any(areas.contains))
        .take(stretchCount)
        .toList();
    final source = matches.isEmpty
        ? [ExploreStretch(name: name, pose: previewPose, areas: areas)]
        : matches;

    return RoutineSummary(
      name: name,
      minutes: minutes,
      equipmentLabel: 'None',
      stretches: [
        for (final stretch in source)
          StretchPreview(name: stretch.name, pose: stretch.pose),
      ],
    );
  }
}

/// Demo content for the Explore screen — ported from the prototype's
/// `ROUTINES`/`STRETCHES` tables, minus the fields Explore doesn't show
/// (steps, cautions, equipment…), same as [TodayDemoData] elsewhere.
class ExploreDemoData {
  const ExploreDemoData._();

  static const areas = [
    ExploreArea('neck', 'Neck'),
    ExploreArea('shoulders', 'Shoulders'),
    ExploreArea('chest', 'Chest'),
    ExploreArea('upperback', 'Upper back'),
    ExploreArea('lowerback', 'Lower back'),
    ExploreArea('spine', 'Spine'),
    ExploreArea('hips', 'Hips'),
    ExploreArea('glutes', 'Glutes'),
    ExploreArea('hamstrings', 'Hamstrings'),
    ExploreArea('quads', 'Quads'),
    ExploreArea('calves', 'Calves'),
    ExploreArea('wrists', 'Wrists'),
  ];

  static const routines = [
    ExploreRoutine(
      name: 'Morning wake-up',
      minutes: 4,
      stretchCount: 6,
      sequence: 'Standing → Floor',
      previewPose: StretchPoses.reach,
      areas: [
        'shoulders',
        'upperback',
        'spine',
        'lowerback',
        'hamstrings',
        'calves',
        'chest',
      ],
    ),
    ExploreRoutine(
      name: 'Desk reset',
      minutes: 4,
      stretchCount: 6,
      sequence: 'Standing → Seated',
      previewPose: StretchPoses.necktilt,
      areas: [
        'neck',
        'shoulders',
        'upperback',
        'spine',
        'wrists',
        'lowerback',
        'hips',
        'glutes',
      ],
    ),
    ExploreRoutine(
      name: 'Neck & shoulders',
      minutes: 3,
      stretchCount: 5,
      sequence: 'Standing → Floor',
      previewPose: StretchPoses.necktilt,
      areas: ['neck', 'shoulders', 'upperback', 'chest', 'spine'],
    ),
    ExploreRoutine(
      name: 'Lower back relief',
      minutes: 4,
      stretchCount: 5,
      sequence: 'Floor',
      previewPose: StretchPoses.kneehug,
      areas: [
        'lowerback',
        'glutes',
        'hips',
        'spine',
        'chest',
        'upperback',
        'shoulders',
      ],
    ),
    ExploreRoutine(
      name: 'Tight hips',
      minutes: 4,
      stretchCount: 5,
      sequence: 'Seated → Floor',
      previewPose: StretchPoses.butterfly,
      areas: ['hips', 'quads', 'glutes', 'spine', 'lowerback', 'chest'],
    ),
    ExploreRoutine(
      name: 'Hamstring opener',
      minutes: 4,
      stretchCount: 5,
      sequence: 'Standing → Seated → Floor',
      previewPose: StretchPoses.fold,
      areas: ['hamstrings', 'lowerback', 'calves', 'shoulders'],
    ),
    ExploreRoutine(
      name: "Runner's cooldown",
      minutes: 3,
      stretchCount: 5,
      sequence: 'Standing → Floor',
      previewPose: StretchPoses.quad,
      areas: ['quads', 'hips', 'calves', 'hamstrings', 'lowerback', 'glutes'],
    ),
    ExploreRoutine(
      name: 'Bedtime wind-down',
      minutes: 4,
      stretchCount: 5,
      sequence: 'Seated → Floor',
      previewPose: StretchPoses.butterfly,
      areas: ['hips', 'spine', 'glutes', 'lowerback', 'chest', 'shoulders'],
    ),
    ExploreRoutine(
      name: 'Knee-friendly full body',
      minutes: 5,
      stretchCount: 7,
      sequence: 'Standing → Seated → Floor',
      previewPose: StretchPoses.reach,
      areas: [
        'shoulders',
        'upperback',
        'spine',
        'lowerback',
        'hamstrings',
        'calves',
        'chest',
      ],
    ),
    ExploreRoutine(
      name: 'Posture reset',
      minutes: 4,
      stretchCount: 6,
      sequence: 'Standing → Floor',
      previewPose: StretchPoses.wallchest,
      areas: ['chest', 'shoulders', 'upperback', 'spine', 'lowerback'],
      isPremium: true,
    ),
    ExploreRoutine(
      name: 'Splits prep',
      minutes: 4,
      stretchCount: 5,
      sequence: 'Floor',
      previewPose: StretchPoses.lunge,
      areas: ['hips', 'quads', 'hamstrings', 'glutes', 'calves', 'shoulders'],
      isPremium: true,
    ),
    ExploreRoutine(
      name: 'Deep full-body',
      minutes: 7,
      stretchCount: 8,
      sequence: 'Standing → Floor → Seated → Floor',
      previewPose: StretchPoses.reach,
      areas: [
        'shoulders',
        'upperback',
        'spine',
        'hamstrings',
        'lowerback',
        'calves',
        'hips',
        'quads',
        'glutes',
        'chest',
      ],
      isPremium: true,
    ),
  ];

  static const stretches = [
    ExploreStretch(
      name: 'Overhead reach',
      pose: StretchPoses.reach,
      areas: ['shoulders', 'upperback', 'spine'],
    ),
    ExploreStretch(
      name: 'Standing side bend',
      pose: StretchPoses.sidebend,
      areas: ['spine', 'lowerback', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Neck side tilt',
      pose: StretchPoses.necktilt,
      areas: ['neck'],
    ),
    ExploreStretch(
      name: 'Cross-body shoulder',
      pose: StretchPoses.cross,
      areas: ['shoulders', 'upperback'],
    ),
    ExploreStretch(
      name: 'Wall chest opener',
      pose: StretchPoses.wallchest,
      areas: ['chest', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Standing forward fold',
      pose: StretchPoses.fold,
      areas: ['hamstrings', 'lowerback', 'calves'],
    ),
    ExploreStretch(
      name: 'Standing quad stretch',
      pose: StretchPoses.quad,
      areas: ['quads', 'hips'],
    ),
    ExploreStretch(
      name: 'Wall calf stretch',
      pose: StretchPoses.calf,
      areas: ['calves'],
    ),
    ExploreStretch(
      name: 'Wrist flexor stretch',
      pose: StretchPoses.wrist,
      areas: ['wrists'],
    ),
    ExploreStretch(
      name: 'Seated chair twist',
      pose: StretchPoses.chairtwist,
      areas: ['spine', 'upperback', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Chair figure-4',
      pose: StretchPoses.chairfig4,
      areas: ['hips', 'glutes'],
    ),
    ExploreStretch(
      name: 'Seated forward fold',
      pose: StretchPoses.seatedfold,
      areas: ['hamstrings', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Butterfly',
      pose: StretchPoses.butterfly,
      areas: ['hips'],
    ),
    ExploreStretch(
      name: 'Seated spinal twist',
      pose: StretchPoses.seatedtwist,
      areas: ['spine', 'glutes'],
    ),
    ExploreStretch(
      name: 'Strap hamstring stretch',
      pose: StretchPoses.strap,
      areas: ['hamstrings', 'calves'],
    ),
    ExploreStretch(
      name: 'Knee-to-chest',
      pose: StretchPoses.kneehug,
      areas: ['lowerback', 'glutes'],
    ),
    ExploreStretch(
      name: 'Lying figure-4',
      pose: StretchPoses.fig4,
      areas: ['hips', 'glutes'],
    ),
    ExploreStretch(
      name: 'Supine twist',
      pose: StretchPoses.supinetwist,
      areas: ['spine', 'lowerback', 'chest'],
    ),
    ExploreStretch(
      name: "Child's pose",
      pose: StretchPoses.child,
      areas: ['lowerback', 'hips', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Cat-cow',
      pose: StretchPoses.catcow,
      areas: ['spine', 'lowerback', 'upperback'],
    ),
    ExploreStretch(
      name: 'Low lunge',
      pose: StretchPoses.lunge,
      areas: ['hips', 'quads'],
    ),
    ExploreStretch(
      name: 'Cobra',
      pose: StretchPoses.cobra,
      areas: ['lowerback', 'chest', 'spine'],
    ),
    ExploreStretch(
      name: 'Downward dog',
      pose: StretchPoses.downdog,
      areas: ['hamstrings', 'calves', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Pigeon',
      pose: StretchPoses.pigeon,
      areas: ['hips', 'glutes'],
    ),
    ExploreStretch(
      name: 'Thread the needle',
      pose: StretchPoses.thread,
      areas: ['upperback', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Foam roller chest opener',
      pose: StretchPoses.roller,
      areas: ['upperback', 'chest'],
    ),
    ExploreStretch(
      name: 'Band chest stretch',
      pose: StretchPoses.bandpull,
      areas: ['chest', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Supported bridge',
      pose: StretchPoses.bridge,
      areas: ['hips', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Half splits',
      pose: StretchPoses.halfsplit,
      areas: ['hamstrings'],
    ),
    ExploreStretch(
      name: 'Standing torso rotation',
      pose: StretchPoses.torsotwist,
      areas: ['spine', 'upperback'],
    ),
    ExploreStretch(
      name: 'Overhead Triceps Stretch',
      pose: StretchPoses.overheadtriceps,
      areas: ['shoulders', 'upperback'],
    ),
    ExploreStretch(
      name: 'Clasped-Hands Chest Opener',
      pose: StretchPoses.chestclasp,
      areas: ['chest', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Neck Forward Stretch',
      pose: StretchPoses.neckforward,
      areas: ['neck', 'upperback'],
    ),
    ExploreStretch(
      name: 'Chin Tuck',
      pose: StretchPoses.chintuck,
      areas: ['neck'],
    ),
    ExploreStretch(
      name: 'Standing Hamstring Stretch',
      pose: StretchPoses.standhamstring,
      areas: ['hamstrings', 'calves'],
    ),
    ExploreStretch(
      name: 'Bent-Knee Calf Stretch',
      pose: StretchPoses.soleus,
      areas: ['calves'],
    ),
    ExploreStretch(
      name: 'Standing Figure-4',
      pose: StretchPoses.standfig4,
      areas: ['hips', 'glutes'],
    ),
    ExploreStretch(
      name: 'Wall Lat Stretch',
      pose: StretchPoses.walllat,
      areas: ['shoulders', 'upperback'],
    ),
    ExploreStretch(
      name: 'High Lunge Reach',
      pose: StretchPoses.highlunge,
      areas: ['hips', 'quads'],
    ),
    ExploreStretch(
      name: 'Pyramid Pose',
      pose: StretchPoses.pyramid,
      areas: ['hamstrings', 'calves'],
    ),
    ExploreStretch(
      name: 'Leg Swings',
      pose: StretchPoses.legswing,
      areas: ['hamstrings', 'hips'],
    ),
    ExploreStretch(
      name: 'Upper-Back Hug Stretch',
      pose: StretchPoses.hugstretch,
      areas: ['upperback', 'shoulders'],
    ),
    ExploreStretch(
      name: 'Wrist Extensor Stretch',
      pose: StretchPoses.wristext,
      areas: ['wrists'],
    ),
    ExploreStretch(
      name: 'Deep Squat Hold',
      pose: StretchPoses.squat,
      areas: ['hips', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Seated Single-Leg Hamstring Stretch',
      pose: StretchPoses.seatedsingle,
      areas: ['hamstrings', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Chair Forward Fold',
      pose: StretchPoses.chairfold,
      areas: ['hamstrings', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Seated Cat-Cow',
      pose: StretchPoses.chaircatcow,
      areas: ['spine', 'lowerback', 'upperback'],
    ),
    ExploreStretch(
      name: 'Sphinx Pose',
      pose: StretchPoses.sphinx,
      areas: ['lowerback', 'spine', 'chest'],
    ),
    ExploreStretch(
      name: 'Happy Baby Pose',
      pose: StretchPoses.happybaby,
      areas: ['hips', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Puppy Pose',
      pose: StretchPoses.puppy,
      areas: ['shoulders', 'upperback', 'spine'],
    ),
    ExploreStretch(
      name: 'Prone Quad Stretch',
      pose: StretchPoses.pronequad,
      areas: ['quads', 'hips'],
    ),
    ExploreStretch(
      name: 'Camel Pose',
      pose: StretchPoses.camel,
      areas: ['chest', 'spine', 'quads'],
    ),
    ExploreStretch(
      name: 'Rocking Hip Stretch',
      pose: StretchPoses.rockback,
      areas: ['hips', 'lowerback'],
    ),
    ExploreStretch(
      name: 'Supine Full-Body Reach',
      pose: StretchPoses.supinereach,
      areas: ['spine', 'shoulders', 'chest'],
    ),
    ExploreStretch(
      name: 'Reverse Tabletop',
      pose: StretchPoses.tabletop,
      areas: ['chest', 'shoulders', 'wrists'],
    ),
  ];
}
