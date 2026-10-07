import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local cache for tracking whether the user currently has a paused routine session.
/// Allows instant (0ms) checks before screen builds to avoid unnecessary shimmers.
class PausedSessionCache {
  static const _storage = FlutterSecureStorage();
  static const _key = 'has_paused_user_routine';
  static bool _inMemoryCache = false;

  /// Fast synchronous check in memory (0ms delay).
  static bool get hasPausedRoutine => _inMemoryCache;

  /// Loads the cached flag from secure storage during app initialization.
  static Future<void> init() async {
    try {
      final value = await _storage.read(key: _key);
      _inMemoryCache = value == 'true';
    } catch (_) {
      _inMemoryCache = false;
    }
  }

  /// Updates the cached flag in memory and secure storage.
  static Future<void> setHasPausedRoutine(bool hasPaused) async {
    _inMemoryCache = hasPaused;
    try {
      if (hasPaused) {
        await _storage.write(key: _key, value: 'true');
      } else {
        await _storage.write(key: _key, value: 'false');
      }
    } catch (_) {}
  }
}
