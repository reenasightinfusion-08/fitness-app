import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:fitness_app/services/auth_service.dart';

/// What the backend needs to verify a Sign in with Apple login
/// (`POST /api/auth/apple`).
class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    required this.nonce,
    this.name,
  });

  final String identityToken;

  /// The unhashed nonce; Apple was given its SHA-256, and the backend checks the token carries it.
  final String nonce;

  /// Only present the first time this Apple ID signs in to the app.
  final String? name;
}

/// Wraps the Sign in with Apple SDK. iOS only: Apple requires it next to other
/// social logins on iOS, and the Android build doesn't offer it.
class AppleAuthService {
  static bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the Apple button is shown: iPhone and iPad only.
  static bool get showButton => isSupported;

  /// The credential Apple issued, or null if the user dismissed the Apple sheet.
  Future<AppleSignInResult?> getCredential() async {
    if (!isSupported) {
      throw AuthException("Sign in with Apple isn't available on this device.");
    }
    final rawNonce = _newNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw AuthException("Couldn't sign in with Apple. Try again.");
      }
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');
      return AppleSignInResult(
        identityToken: identityToken,
        nonce: rawNonce,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[AppleAuth] ${e.code} | ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AuthException("Couldn't sign in with Apple. Try again.");
    } on SignInWithAppleNotSupportedException catch (e) {
      debugPrint('[AppleAuth] not supported: $e');
      throw AuthException("Sign in with Apple isn't available on this device.");
    } on SignInWithAppleException catch (e) {
      debugPrint('[AppleAuth] $e');
      throw AuthException("Couldn't sign in with Apple. Try again.");
    }
  }

  static String _newNonce() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
