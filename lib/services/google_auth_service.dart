import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:fitness_app/services/auth_service.dart';

/// Wraps the Google Sign-In SDK and hands back an ID token for the backend to
/// verify (`POST /api/auth/google`).
///
/// The Web OAuth client ID must be passed at build time:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com`
/// (the same ID goes in the backend's `GOOGLE_CLIENT_IDS`).
class GoogleAuthService {
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '668877744444-tnmlhbmciv0ar75nsl4cva7dhih3dt3b.apps.googleusercontent.com',
  );

  static Future<void>? _initialized;

  Future<void> _ensureInitialized() {
    return _initialized ??= GoogleSignIn.instance
        .initialize(serverClientId: _serverClientId)
        .catchError((Object e) {
          _initialized = null;
          throw e;
        });
  }

  /// The signed-in account's ID token, or null if the user dismissed the
  /// Google account picker.
  Future<String?> getIdToken() async {
    if (_serverClientId.isEmpty) {
      throw AuthException('Google sign-in is not set up yet.');
    }
    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw AuthException("Google sign-in isn't available on this device.");
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthException("Couldn't sign in with Google. Try again.");
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      debugPrint('[GoogleAuth] ${e.code} | ${e.description} | ${e.details}');
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException("Couldn't sign in with Google. Try again.");
    }
  }

  /// Forgets the chosen Google account so the next sign-in shows the picker.
  Future<void> signOut() async {
    if (_initialized == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
