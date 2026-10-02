import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/core/providers/todays_plan_provider.dart';
import 'package:fitness_app/services/auth_service.dart';

/// A stretch the user marked as painful after a session.
class HurtStretch {
  const HurtStretch({required this.id, required this.name});

  factory HurtStretch.fromJson(Map<String, dynamic> json) => HurtStretch(
    id: json['stretch'] as String,
    name: json['name'] as String? ?? 'Stretch',
  );

  final String id;
  final String name;
}

/// The `hurtStretches` list on the user's profile (`/api/users/me`). The server
/// leaves any routine containing one of these out of the daily plan. Empty
/// without an account.
///
/// Invalidate this on logout so the next account doesn't see the last one's list.
class HurtStretchesController extends AsyncNotifier<List<HurtStretch>> {
  @override
  Future<List<HurtStretch>> build() async {
    final auth = ref.watch(authServiceProvider);
    if (!await auth.hasSession()) return const [];
    return [
      for (final item in await auth.getHurtStretches())
        HurtStretch.fromJson(item as Map<String, dynamic>),
    ];
  }

  bool isHurt(String stretchId) =>
      state.valueOrNull?.any((h) => h.id == stretchId) ?? false;

  /// Marks or unmarks [stretchId] straight away and saves it, putting the list
  /// back and rethrowing the server's reason if that fails. The daily plan is
  /// refreshed because the server rebuilds it without (or with) that stretch.
  Future<void> setHurt(String stretchId, String name, bool hurt) async {
    final auth = ref.read(authServiceProvider);
    if (!await auth.hasSession()) {
      throw AuthException('Sign in to save this.');
    }
    final previous = state.valueOrNull ?? await future;
    final without = [
      for (final h in previous)
        if (h.id != stretchId) h,
    ];
    state = AsyncData(
      hurt ? [...without, HurtStretch(id: stretchId, name: name)] : without,
    );
    try {
      if (hurt) {
        await auth.addHurtStretch(stretchId);
      } else {
        await auth.removeHurtStretch(stretchId);
      }
      ref.invalidate(todaysPlanProvider);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final hurtStretchesProvider =
    AsyncNotifierProvider<HurtStretchesController, List<HurtStretch>>(
      HurtStretchesController.new,
    );
