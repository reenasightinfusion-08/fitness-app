import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/home/models/todays_plan_model.dart';

/// Today's routine from `GET /api/plans/today`, which the server picks from the
/// profile saved during onboarding.
final todaysPlanProvider = FutureProvider<TodaysPlanModel>(
  (ref) async => TodaysPlanModel.fromJson(
    await ref.watch(authServiceProvider).getTodaysPlan(),
  ),
);
