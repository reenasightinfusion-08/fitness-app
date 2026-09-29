import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_guide.dart';

/// One stretch document from the backend's `stretches` collection. Carries
/// every field the API stores, and converts to the smaller view models the
/// screens already use ([StretchPreview], [StretchGuide], [ExploreStretch]).
class StretchModel {
  const StretchModel({
    required this.id,
    required this.poseKey,
    required this.name,
    required this.position,
    required this.areas,
    required this.feel,
    this.level = RoutineLevel.beginner,
    this.equipment = const [],
    this.isEachSide = false,
    this.isDynamic = false,
    this.isKneeling = false,
    this.defaultHoldSeconds = 30,
    this.defaultRepCount = 1,
    this.setupCue = '',
    this.feelCue,
    this.steps = const [],
    this.commonMistake = '',
    this.easier = '',
    this.harder = '',
    this.cautions = '',
    this.thumbnailUrl,
    this.videoUrl,
    this.isActive = true,
  });

  factory StretchModel.fromJson(Map<String, dynamic> json) => StretchModel(
    id: json['_id'] as String,
    poseKey: json['poseKey'] as String,
    name: json['name'] as String,
    position: StretchPosition.values.byName(json['position'] as String),
    areas: List<String>.from(json['areas'] as List? ?? const []),
    feel: json['feel'] as String,
    level: RoutineLevel.values.byName(json['level'] as String? ?? 'beginner'),
    equipment: List<String>.from(json['equipment'] as List? ?? const []),
    isEachSide: json['isEachSide'] as bool? ?? false,
    isDynamic: json['isDynamic'] as bool? ?? false,
    isKneeling: json['isKneeling'] as bool? ?? false,
    defaultHoldSeconds: json['defaultHoldSeconds'] as int? ?? 30,
    defaultRepCount: json['defaultRepCount'] as int? ?? 1,
    setupCue: json['setupCue'] as String? ?? '',
    feelCue: json['feelCue'] as String?,
    steps: List<String>.from(json['steps'] as List? ?? const []),
    commonMistake: json['commonMistake'] as String? ?? '',
    easier: json['easier'] as String? ?? '',
    harder: json['harder'] as String? ?? '',
    cautions: json['cautions'] as String? ?? '',
    thumbnailUrl: json['thumbnailUrl'] as String?,
    videoUrl: json['videoUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  final String id;

  /// Name of the [StretchPoses] constant that draws this stretch.
  final String poseKey;
  final String name;
  final StretchPosition position;

  /// [ExploreArea.key]s this stretch targets.
  final List<String> areas;
  final RoutineLevel level;
  final List<String> equipment;
  final bool isEachSide;
  final bool isDynamic;
  final bool isKneeling;

  /// Per side, in seconds.
  final int defaultHoldSeconds;
  final int defaultRepCount;
  final String setupCue;
  final String? feelCue;
  final String feel;
  final List<String> steps;
  final String commonMistake;
  final String easier;
  final String harder;
  final String cautions;
  final String? thumbnailUrl;
  final String? videoUrl;
  final bool isActive;

  /// Total hold time — same formula the backend stores as `totalHoldSeconds`.
  int get totalHoldSeconds =>
      defaultHoldSeconds * defaultRepCount * (isEachSide ? 2 : 1);

  /// The illustration for this stretch. Throws if the backend sends a
  /// `poseKey` the app has no drawing for, so a bad row fails loudly.
  StretchPose get pose =>
      StretchPoses.byKey[poseKey] ??
      (throw FormatException('Unknown poseKey "$poseKey"'));

  StretchPreview toPreview() => StretchPreview(
    name: name,
    pose: pose,
    holdSeconds: defaultHoldSeconds,
    repCount: defaultRepCount,
    position: position,
    isEachSide: isEachSide,
    setupCue: setupCue.isEmpty ? 'Get into position.' : setupCue,
    feelCue: feelCue,
  );

  StretchGuide toGuide() => StretchGuide(
    position: position,
    isEachSide: isEachSide,
    isDynamic: isDynamic,
    isKneeling: isKneeling,
    level: level,
    equipment: equipment,
    feel: feel,
    steps: steps,
    commonMistake: commonMistake,
    easier: easier,
    harder: harder,
    cautions: cautions,
  );

  ExploreStretch toExploreStretch() =>
      ExploreStretch(name: name, pose: pose, areas: areas);
}
