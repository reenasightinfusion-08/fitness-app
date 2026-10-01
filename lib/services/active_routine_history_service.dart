import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Reads the user's completed-routine history from the server.
class ActiveRoutineHistoryService {
  ActiveRoutineHistoryService(this.authService);

  final AuthService authService;

  /// Every completed routine for the signed-in user, newest first. The server
  /// drops `stretches` here, so this is a slim list for the Progress history.
  Future<List<ActiveRoutineModel>> history() async {
    final data = await authService.getRoutineHistory();
    return data
        .map((json) => ActiveRoutineModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
