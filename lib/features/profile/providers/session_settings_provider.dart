import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/profile/models/session_settings.dart';

/// The signed-in user's session preferences. Loaded from the profile at
/// sign-in; changed only when the Session settings screen's Save is pressed.
class SessionSettingsController extends Notifier<SessionSettings> {
  @override
  SessionSettings build() => const SessionSettings();

  /// Applies the `sessionSettings` saved on the user's profile, or the
  /// defaults when there are none yet.
  void loadFromApi(Map<String, dynamic> user) {
    final saved = user['sessionSettings'];
    state = saved is Map<String, dynamic>
        ? SessionSettings.fromJson(saved)
        : const SessionSettings();
  }

  /// Makes [next] the settings on this device, then saves them to the account.
  /// Returns false when the account couldn't be reached; the settings still
  /// apply here.
  Future<bool> apply(SessionSettings next) async {
    state = next;
    try {
      final auth = ref.read(authServiceProvider);
      if (!await auth.hasSession()) return true;
      await auth.updateMe({'sessionSettings': next.toJson()});
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sessionSettingsProvider =
    NotifierProvider<SessionSettingsController, SessionSettings>(
      SessionSettingsController.new,
    );
