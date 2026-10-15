import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/home/models/plan_overview_model.dart';

/// The user's whole plan from `GET /api/plans/overview`, shown right after
/// onboarding.
final planOverviewProvider = FutureProvider.autoDispose<PlanOverviewModel>(
  (ref) async => PlanOverviewModel.fromJson(
    await ref.watch(authServiceProvider).getPlanOverview(),
  ),
);
