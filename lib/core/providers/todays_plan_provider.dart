import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/models/todays_plan_model.dart';

/// Today's routine from `GET /api/plans/today`, which the server picks from the
/// profile saved during onboarding. Without an account ("Explore with a sample
/// account") there is no profile to plan from, so that visit keeps the demo plan.
final todaysPlanProvider = FutureProvider.autoDispose<TodaysPlanModel>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (!await authService.hasSession()) {
    return const TodaysPlanModel(
      routine: TodayDemoData.todaysPlan,
      completedToday: false,
    );
  }
  return TodaysPlanModel.fromJson(await authService.getTodaysPlan());
});
