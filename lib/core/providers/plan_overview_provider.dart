import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/home/models/plan_overview_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';

/// The user's whole plan from `GET /api/plans/overview`, shown right after
/// onboarding. Without an account there is nothing to plan from, so the demo
/// routine stands in as a one-day plan.
final planOverviewProvider = FutureProvider.autoDispose<PlanOverviewModel>((
  ref,
) async {
  final authService = ref.watch(authServiceProvider);
  if (!await authService.hasSession()) {
    return const PlanOverviewModel(
      days: [
        PlanDayModel(day: 1, isToday: true, routine: TodayDemoData.todaysPlan),
      ],
    );
  }
  return PlanOverviewModel.fromJson(await authService.getPlanOverview());
});
