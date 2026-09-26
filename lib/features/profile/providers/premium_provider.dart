import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the account has Premium — the prototype's `a.premium`. Shared
/// by the Profile menu subtitle, Account & security, and the Premium
/// screen itself. There's no payment backend yet, so "buying" just flips
/// this flag.
class PremiumController extends Notifier<bool> {
  @override
  bool build() => false;

  void setPremium(bool value) => state = value;
}

final premiumProvider = NotifierProvider<PremiumController, bool>(
  PremiumController.new,
);
