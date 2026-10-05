import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';

/// How the signed-in user can authenticate, as reported by `GET /users/me`.
class SignInMethods {
  const SignInMethods({required this.hasPassword, required this.hasGoogle});

  final bool hasPassword;
  final bool hasGoogle;

  String get label => switch ((hasPassword, hasGoogle)) {
    (true, true) => 'Email and Google',
    (false, true) => 'Google',
    _ => 'Email and password',
  };
}

/// Falls back to email and password when there is no session (the sample
/// account) or the server can't be reached, so the screen never breaks.
final signInMethodsProvider = FutureProvider.autoDispose<SignInMethods>((
  ref,
) async {
  try {
    final me = await ref.watch(authServiceProvider).getMe();
    return SignInMethods(
      hasPassword: me['hasPassword'] as bool? ?? true,
      hasGoogle: me['hasGoogle'] as bool? ?? false,
    );
  } catch (_) {
    return const SignInMethods(hasPassword: true, hasGoogle: false);
  }
});
