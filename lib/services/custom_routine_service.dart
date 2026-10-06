import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Reads and writes the signed-in user's own routines
/// (`/api/custom-routines`). Everything goes through [AuthService] so the
/// token, host probing and `{ success, message, data }` handling stay in one place.
class CustomRoutineService {
  CustomRoutineService(this.authService);

  final AuthService authService;

  /// The user's routines, newest first, with every stretch fully populated.
  Future<List<RoutineSummary>> fetch() async {
    final data = await authService.getCustomRoutines();
    final routines = data
        .map((json) => RoutineSummary.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final routine in routines) {
      for (final stretch in routine.stretches) {
        final model = stretch.model;
        VideoFrameService.prefetch(model?.videoUrl, model?.defaultHoldSeconds ?? 30);
      }
    }
    return routines;
  }

  /// Saves [draft]. The server only replies "created", so call [fetch] to get
  /// the stored record (and its id) back.
  Future<void> create(RoutineSummary draft) async {
    if (!await authService.hasSession()) {
      throw AuthException('Sign in to save your routines.');
    }
    await authService.createCustomRoutine({
      'name': draft.name.trim(),
      'transitionSeconds': draft.transitionSeconds,
      'stretches': [for (final item in draft.stretches) _itemJson(item)],
    });
  }

  /// Whether every stretch of [routine] can be stored on the server.
  bool canSave(RoutineSummary routine) =>
      routine.stretches.isNotEmpty &&
      routine.stretches.every(
        (item) => item.model != null || _poseKeyOf(item.pose) != null,
      );

  Future<void> delete(String id) => authService.deleteCustomRoutine(id);

  /// One routine item. The server needs the stretch's id or its `poseKey`;
  /// stretches picked from the library carry their model, and copies of
  /// older demo routines fall back to the key of their drawing.
  Map<String, dynamic> _itemJson(StretchPreview item) {
    final model = item.model;
    final poseKey = model?.poseKey ?? _poseKeyOf(item.pose);
    if (model == null && poseKey == null) {
      throw AuthException('"${item.name}" can\'t be saved in a routine yet.');
    }
    return {
      if (model != null) 'stretch': model.id else 'poseKey': poseKey,
      'holdSeconds': item.holdSeconds,
      'repCount': item.repCount,
    };
  }

  static String? _poseKeyOf(StretchPose pose) {
    for (final entry in StretchPoses.byKey.entries) {
      if (entry.value == pose) return entry.key;
    }
    return null;
  }
}
