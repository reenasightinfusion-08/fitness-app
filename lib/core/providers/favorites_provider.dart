import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Ids of the routines the user favourited, oldest first — the `favorites`
/// list on their profile (`/api/users/me`). Library and custom routines share
/// one list because their ids never collide. Empty without an account.
///
/// Invalidate this on logout so the next account doesn't see the last one's list.
class FavoritesController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final auth = ref.watch(authServiceProvider);
    if (!await auth.hasSession()) return const [];
    return auth.getFavorites();
  }

  bool isFavorite(String routineId) =>
      state.valueOrNull?.contains(routineId) ?? false;

  /// Flips [routineId] straight away and saves it, putting it back and
  /// rethrowing the server's reason if that fails.
  Future<void> toggle(String routineId) async {
    final auth = ref.read(authServiceProvider);
    if (!await auth.hasSession()) {
      throw AuthException('Sign in to save favourites.');
    }
    final previous = state.valueOrNull ?? await future;
    final wasFavorite = previous.contains(routineId);
    state = AsyncData(
      wasFavorite
          ? [
              for (final id in previous)
                if (id != routineId) id,
            ]
          : [...previous, routineId],
    );
    try {
      if (wasFavorite) {
        await auth.removeFavorite(routineId);
      } else {
        await auth.addFavorite(routineId);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, List<String>>(
      FavoritesController.new,
    );
