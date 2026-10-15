import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'ad_service.dart';

/// "Watch an ad to unlock for 24h". Never blocks the user when ads are
/// unavailable (unsupported platform, no ad ready, Premium).
class AdGate {
  static const _validFor = Duration(hours: 24);
  static const _storage = FlutterSecureStorage();
  static final Map<String, DateTime> _memory = {};

  /// Key of the "ad-free for 24h" reward.
  static const adFreeKey = 'adfree';

  /// Synchronous check, valid after [init].
  static bool get adFreeNow {
    final at = _memory[adFreeKey];
    return at != null && DateTime.now().difference(at) < _validFor;
  }

  static Future<void> init() async {
    try {
      final raw = await _storage.read(key: 'ad_gate_$adFreeKey');
      final ms = raw == null ? null : int.tryParse(raw);
      if (ms != null) _memory[adFreeKey] = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {}
  }

  static Future<bool> isUnlocked(String key) async {
    var at = _memory[key];
    if (at == null) {
      try {
        final raw = await _storage.read(key: 'ad_gate_$key');
        final ms = raw == null ? null : int.tryParse(raw);
        if (ms != null) at = DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (_) {}
    }
    return at != null && DateTime.now().difference(at) < _validFor;
  }

  static Future<void> _unlock(String key) async {
    final now = DateTime.now();
    _memory[key] = now;
    try {
      await _storage.write(
        key: 'ad_gate_$key',
        value: '${now.millisecondsSinceEpoch}',
      );
    } catch (_) {}
  }

  /// Offers a rewarded ad in exchange for [onUnlocked]. With [blocking] false
  /// the action also proceeds when the user declines (a pure "support us"
  /// prompt); with true it only proceeds after the reward.
  static Future<void> run(
    BuildContext context, {
    required String key,
    required String title,
    required String message,
    required VoidCallback onUnlocked,
    bool interstitialStyle = false,
    bool blocking = true,
  }) async {
    final ready = interstitialStyle
        ? AdService.rewardedInterstitialReady
        : AdService.rewardedReady;
    if (!AdService.supported ||
        !AdService.adsEnabled() ||
        !ready ||
        await isUnlocked(key)) {
      onUnlocked();
      return;
    }
    if (!context.mounted) return;

    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Watch ad',
              style: TextStyle(
                color: ctx.colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (watch != true) {
      if (!blocking) onUnlocked();
      return;
    }

    var earned = false;
    void onReward(_) => earned = true;
    void onClosed() {
      if (!earned) {
        if (!blocking) onUnlocked();
        return;
      }
      _unlock(key);
      onUnlocked();
    }

    final shown = interstitialStyle
        ? AdService.showRewardedInterstitial(
            onReward: onReward,
            onClosed: onClosed,
          )
        : AdService.showRewarded(onReward: onReward, onClosed: onClosed);
    if (!shown) onUnlocked();
  }
}
