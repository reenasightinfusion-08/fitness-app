import 'package:flutter/foundation.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';

/// Where a stretch is done — mirrors the prototype's `POS_LABEL`. Drives
/// both the fact-tile sequence line and the player's per-stretch layout.
enum StretchPosition { standing, seated, floor }

extension StretchPositionLabel on StretchPosition {
  String get label => switch (this) {
    StretchPosition.standing => 'Standing',
    StretchPosition.seated => 'Seated',
    StretchPosition.floor => 'Floor',
  };
}

/// Mirrors the prototype's `LEVELS` — how demanding a routine is overall.
enum RoutineLevel { beginner, intermediate, advanced }

extension RoutineLevelLabel on RoutineLevel {
  String get label => switch (this) {
    RoutineLevel.beginner => 'Beginner',
    RoutineLevel.intermediate => 'Intermediate',
    RoutineLevel.advanced => 'Advanced',
  };
}

/// One stretch's illustration + name, as shown in the today's-plan figrow,
/// quick-pick tiles, the routine detail list and the session player.
@immutable
class StretchPreview {
  const StretchPreview({
    required this.name,
    required this.pose,
    this.holdSeconds = 30,
    this.repCount = 1,
    this.position = StretchPosition.standing,
    this.isEachSide = false,
    this.setupCue = 'Get into position.',
    this.feelCue,
    this.model,
  });

  final String name;
  final StretchPose pose;

  /// How long a single hold lasts — the prototype's per-stretch `hold`.
  final int holdSeconds;

  /// How many times the hold repeats — the prototype's per-stretch `reps`.
  final int repCount;
  final StretchPosition position;

  /// Whether the hold repeats on the other side (the player inserts a
  /// "Switch sides" beat between the two).
  final bool isEachSide;

  /// Read out while getting into the stretch, before the hold starts.
  final String setupCue;

  /// Read out during the hold, e.g. "Feel it: down the side of your leg."
  /// Falls back to a generic breathing cue when unset.
  final String? feelCue;

  /// Full backend stretch document, if fetched from API.
  final StretchModel? model;

  /// Total time spent holding this stretch — hold × reps, doubled when it
  /// is done on each side. Mirrors the backend's `totalHoldSeconds`.
  int get totalHoldSeconds => holdSeconds * repCount * (isEachSide ? 2 : 1);

  /// How the hold reads in a list, e.g. "30s", "30s each side", "40s × 2 each side".
  /// The hold is per side, so this is where "each side" gets said out loud.
  String get holdLabel {
    final reps = repCount > 1 ? ' × $repCount' : '';
    return '${holdSeconds}s$reps${isEachSide ? ' each side' : ''}';
  }

  /// Used by the routine builder to adjust just the hold time or rep count
  /// of a picked stretch without rebuilding the rest of it by hand.
  StretchPreview copyWith({
    int? holdSeconds,
    int? repCount,
    StretchModel? model,
  }) => StretchPreview(
    name: name,
    pose: pose,
    holdSeconds: holdSeconds ?? this.holdSeconds,
    repCount: repCount ?? this.repCount,
    position: position,
    isEachSide: isEachSide,
    setupCue: setupCue,
    feelCue: feelCue,
    model: model ?? this.model,
  );
}

/// A short routine: what it's called, how long it runs, and its stretches
/// in order — mirrors the prototype's `getRoutine()` shape.
@immutable
class RoutineSummary {
  const RoutineSummary({
    this.id,
    required this.name,
    required this.stretches,
    int? minutes,
    int totalSeconds = 0,
    this.blurb,
    this.level = RoutineLevel.beginner,
    this.equipmentLabel = 'None',
    this.tags = const [],
    this.adaptedNotes = const [],
    this.transitionSeconds,
  }) : totalSeconds = totalSeconds > 0 ? totalSeconds : (minutes != null ? minutes * 60 : 0);

  factory RoutineSummary.fromJson(Map<String, dynamic> json) {
    final rawStretches = json['stretches'] as List? ?? [];
    final stretches = rawStretches.map((item) {
      if (item is! Map<String, dynamic>) {
        return const StretchPreview(
          name: 'Unknown Stretch',
          pose: StretchPoses.neutral,
        );
      }

      final stretchJson = item['stretch'];
      if (stretchJson is Map<String, dynamic>) {
        final stretchModel = StretchModel.fromJson(stretchJson);
        final holdSeconds =
            item['holdSeconds'] as int? ?? stretchModel.defaultHoldSeconds;
        final repCount =
            item['repCount'] as int? ?? stretchModel.defaultRepCount;
        return stretchModel.toPreview().copyWith(
          holdSeconds: holdSeconds,
          repCount: repCount,
          model: stretchModel,
        );
      }

      return const StretchPreview(
        name: 'Unknown Stretch',
        pose: StretchPoses.neutral,
      );
    }).toList();

    final equipmentList = List<String>.from(json['equipment'] as List? ?? []);
    final equipmentLabel = equipmentList.isEmpty
        ? 'None'
        : equipmentList
            .map((e) => e.isNotEmpty ? '${e[0].toUpperCase()}${e.substring(1)}' : e)
            .join(', ');

    final rawLevel = json['level'] as String? ?? 'beginner';
    final level = RoutineLevel.values.firstWhere(
      (l) => l.name.toLowerCase() == rawLevel.toLowerCase(),
      orElse: () => RoutineLevel.beginner,
    );

    final totalSeconds = json['totalSeconds'] as int? ?? 0;

    return RoutineSummary(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? 'Untitled Routine',
      totalSeconds: totalSeconds,
      stretches: stretches,
      blurb: json['description'] as String?,
      level: level,
      equipmentLabel: equipmentLabel,
      tags: List<String>.from(json['tags'] as List? ?? []),
      transitionSeconds: json['transitionSeconds'] as int?,
    );
  }

  /// The server's routine id, used to begin it and save progress. Null for
  /// demo and unsaved routines, which can be played but not resumed.
  final String? id;
  final String name;
  final int totalSeconds;
  final List<StretchPreview> stretches;

  /// Computed minutes from totalSeconds (rounded up for full minute counts).
  int get minutes => (totalSeconds / 60).ceil();

  /// Calculates whole minutes component from totalSeconds.
  int get calculatedMinutes => totalSeconds ~/ 60;

  /// Calculates remainder seconds component from totalSeconds.
  int get calculatedSeconds => totalSeconds % 60;

  /// Formatted duration string for UI display (e.g. "2 min 30 sec", "1 min 20 sec", "45 sec").
  String get durationText {
    final m = calculatedMinutes;
    final s = calculatedSeconds;
    if (m > 0 && s > 0) return '$m min $s sec';
    if (m > 0) return '$m min';
    if (s > 0) return '$s sec';
    return '$minutes min';
  }
  final String? blurb;
  final RoutineLevel level;
  final String equipmentLabel;

  /// How long to allow to get into each stretch — the prototype's `B.trans`.
  /// Null means "Auto": more time when moving from standing to the floor.
  final int? transitionSeconds;

  /// e.g. "For your shoulders", "Fits your desk job".
  final List<String> tags;

  /// e.g. "Child's pose → Standing side bend (kneeling)" — the prototype's
  /// "Adapted for you" note, one line per swap.
  final List<String> adaptedNotes;

  /// "Standing → Seated → Floor" — consecutive duplicate positions
  /// collapsed, mirroring the prototype's `seqLine()`.
  String get sequenceLabel {
    final labels = <String>[];
    for (final stretch in stretches) {
      final label = stretch.position.label;
      if (labels.isEmpty || labels.last != label) labels.add(label);
    }
    return labels.join(' → ');
  }
}

/// Demo content for the Today screen — there's no backend yet, so this
/// stands in for what a real plan/streak/history service would return.
class TodayDemoData {
  const TodayDemoData._();

  static const currentStreakDays = 4;

  static const todaysPlan = RoutineSummary(
    name: 'Morning reset',
    minutes: 12,
    blurb: 'Loosen up a stiff neck and shoulders before the day starts.',
    level: RoutineLevel.beginner,
    equipmentLabel: 'None',
    tags: ['For your shoulders', 'Fits your desk job'],
    stretches: [
      StretchPreview(
        name: 'Overhead reach',
        pose: StretchPoses.reach,
        holdSeconds: 30,
        setupCue: 'Stand tall, feet hip-width apart.',
      ),
      StretchPreview(
        name: 'Cross-body shoulder',
        pose: StretchPoses.cross,
        holdSeconds: 30,
        isEachSide: true,
        setupCue: 'Draw one arm gently across your chest.',
      ),
      StretchPreview(
        name: 'Standing forward fold',
        pose: StretchPoses.fold,
        holdSeconds: 30,
        setupCue: 'Hinge from your hips, knees soft.',
        feelCue: 'Feel it: down the back of your legs.',
      ),
      StretchPreview(
        name: 'Standing quad stretch',
        pose: StretchPoses.quad,
        holdSeconds: 30,
        isEachSide: true,
        setupCue: 'Hold onto something steady if you need to.',
      ),
      StretchPreview(
        name: 'Wall calf stretch',
        pose: StretchPoses.calf,
        holdSeconds: 30,
        isEachSide: true,
        setupCue: 'Step one foot back, heel flat on the floor.',
      ),
    ],
  );

  static const pausedSession = StretchPreview(
    name: 'Cross-body shoulder',
    pose: StretchPoses.cross,
  );

  static const _morning = RoutineSummary(
    name: 'Morning',
    minutes: 8,
    blurb: 'A quick wake-up for a stiff neck and shoulders.',
    equipmentLabel: 'None',
    stretches: [
      StretchPreview(
        name: 'Overhead reach',
        pose: StretchPoses.reach,
        holdSeconds: 30,
        setupCue: 'Stand tall, feet hip-width apart.',
      ),
      StretchPreview(
        name: 'Standing forward fold',
        pose: StretchPoses.fold,
        holdSeconds: 30,
        setupCue: 'Hinge from your hips, knees soft.',
      ),
    ],
  );

  static const _deskBreak = RoutineSummary(
    name: 'Desk break',
    minutes: 5,
    blurb: 'Undo an hour of hunching over the keyboard.',
    equipmentLabel: 'Chair',
    stretches: [
      StretchPreview(
        name: 'Cross-body shoulder',
        pose: StretchPoses.cross,
        holdSeconds: 30,
        position: StretchPosition.seated,
        isEachSide: true,
        setupCue: 'Sit tall, away from the backrest.',
      ),
      StretchPreview(
        name: 'Seated twist',
        pose: StretchPoses.seatedtwist,
        holdSeconds: 30,
        position: StretchPosition.seated,
        isEachSide: true,
        setupCue: 'Cross one hand to the opposite knee.',
      ),
    ],
  );

  static const _bedtimeWindDown = RoutineSummary(
    name: 'Bedtime wind-down',
    minutes: 9,
    blurb: 'Long, easy holds to slow your breathing before sleep.',
    level: RoutineLevel.beginner,
    equipmentLabel: 'None',
    adaptedNotes: ["Child's pose → Standing side bend (kneeling)"],
    stretches: [
      StretchPreview(
        name: 'Standing side bend',
        pose: StretchPoses.sidebend,
        holdSeconds: 50,
        isEachSide: true,
        setupCue: 'Reach one arm overhead and lean gently sideways.',
      ),
      StretchPreview(
        name: 'Butterfly',
        pose: StretchPoses.butterfly,
        holdSeconds: 50,
        position: StretchPosition.seated,
        setupCue: 'Sit tall, soles of your feet together.',
        feelCue: 'Feel it: along your inner thighs.',
      ),
    ],
  );

  static const _afterWorkout = RoutineSummary(
    name: 'After a workout',
    minutes: 12,
    blurb: 'Cool your legs down after a hard session.',
    level: RoutineLevel.intermediate,
    equipmentLabel: 'Mat',
    stretches: [
      StretchPreview(
        name: 'Standing quad stretch',
        pose: StretchPoses.quad,
        holdSeconds: 30,
        isEachSide: true,
        setupCue: 'Hold onto something steady if you need to.',
      ),
      StretchPreview(
        name: 'Wall calf stretch',
        pose: StretchPoses.calf,
        holdSeconds: 30,
        isEachSide: true,
        setupCue: 'Step one foot back, heel flat on the floor.',
      ),
    ],
  );

  /// "Quick picks" — each a full routine so tapping one can open the
  /// routine detail screen, same as any other routine card.
  static const quickPicks = [
    _morning,
    _deskBreak,
    _bedtimeWindDown,
    _afterWorkout,
  ];

  /// This week's strip, [today]'s weekday marking the "today" cell and the
  /// three days before it marked done — a stand-in for real history.
  static List<WeekDayModel> weekStrip(DateTime today) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = today.weekday - 1;
    return List.generate(7, (index) {
      final dayDate = today.add(Duration(days: index - todayIndex));
      return WeekDayModel(
        label: labels[index],
        dayOfMonth: dayDate.day,
        isDone: index < todayIndex && index >= todayIndex - 3,
        isToday: index == todayIndex,
      );
    });
  }
}
