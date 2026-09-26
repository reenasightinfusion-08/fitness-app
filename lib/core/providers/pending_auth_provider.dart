import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What verify-email / reset-password are waiting on: the email a code was
/// "sent" to, and — since this prototype has no backend or real mail —
/// the code itself, exactly like the HTML mock's `DB.pending`.
@immutable
class PendingAuth {
  const PendingAuth({required this.email, required this.code});

  final String email;
  final String code;

  PendingAuth withNewCode() => PendingAuth(email: email, code: _generateCode());
}

String _generateCode() => (100000 + Random().nextInt(900000)).toString();

class PendingAuthController extends Notifier<PendingAuth?> {
  @override
  PendingAuth? build() => null;

  /// Called when a signup or forgot-password form is submitted.
  void start(String email) =>
      state = PendingAuth(email: email, code: _generateCode());

  /// "Send a new code".
  void resend() {
    final current = state;
    if (current != null) state = current.withNewCode();
  }

  void clear() => state = null;
}

final pendingAuthProvider =
    NotifierProvider<PendingAuthController, PendingAuth?>(
      PendingAuthController.new,
    );
