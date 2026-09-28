import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The email a signup or forgot-password flow is waiting on a code for.
/// The code itself now lives only on the server (see fitness-backend) —
/// this just tracks which address verify-email / reset-password should
/// submit against.
@immutable
class PendingAuth {
  const PendingAuth({required this.email});

  final String email;
}

class PendingAuthController extends Notifier<PendingAuth?> {
  @override
  PendingAuth? build() => null;

  /// Called once a signup or forgot-password request has been sent.
  void start(String email) => state = PendingAuth(email: email);

  void clear() => state = null;
}

final pendingAuthProvider =
    NotifierProvider<PendingAuthController, PendingAuth?>(
      PendingAuthController.new,
    );
