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

    final rawMinutes = (json['minutes'] as num?)?.toInt() ??
        (json['durationMinutes'] as num?)?.toInt() ??
        (json['duration'] as num?)?.toInt();
    final totalSeconds = (json['totalSeconds'] as num?)?.toInt() ??
        (rawMinutes != null ? rawMinutes * 60 : 0);

    return RoutineSummary(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? 'Untitled Routine',
      totalSeconds: totalSeconds,
      minutes: rawMinutes,
      stretches: stretches,
      blurb: json['description'] as String?,
      level: level,
      equipmentLabel: equipmentLabel,
      tags: List<String>.from(json['tags'] as List? ?? []),
      transitionSeconds: json['transitionSeconds'] as int?,
    );
  }

  /// The server's routine id, used to begin it and save progress. Null for
  /// unsaved routines, which can be played but not resumed.
  final String? id;
  final String name;
  final int totalSeconds;
  final List<StretchPreview> stretches;

  int get effectiveTotalSeconds {
    if (totalSeconds > 0) return totalSeconds;
    if (stretches.isNotEmpty) {
      return stretches.fold<int>(0, (sum, item) => sum + item.totalHoldSeconds);
    }
    return 0;
  }

  /// Computed minutes from effectiveTotalSeconds (rounded up for full minute counts).
  int get minutes => (effectiveTotalSeconds / 60).ceil();

  /// Calculates whole minutes component from effectiveTotalSeconds.
  int get calculatedMinutes => effectiveTotalSeconds ~/ 60;

  /// Calculates remainder seconds component from effectiveTotalSeconds.
  int get calculatedSeconds => effectiveTotalSeconds % 60;

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
