import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Shown wherever today's plan (or the plan overview) can't be loaded. Says why when the server gave a
/// reason (e.g. nothing fits the profile) and offers a retry for network errors.
class TodaysPlanErrorCard extends ConsumerWidget {
  const TodaysPlanErrorCard({super.key, required this.error, this.onRetry});

  final Object error;

  /// What "Try again" does; reloads today's plan when not given.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppEmptyState(
    icon: Icons.cloud_off_rounded,
    title: "Couldn't load today's plan",
    message: switch (error) {
      AuthException(:final message) => message,
      _ => 'Check your connection and try again.',
    },
    actionLabel: 'Try again',
    onAction: onRetry ?? () => ref.invalidate(todaysPlanProvider),
  );
}
