import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/widgets/app_bottom_sheet.dart';
import 'ad_service.dart';
import 'ad_slot.dart';

/// "Watch a short ad to unlock for 24h" gate for optional extras. Never
/// blocks the user when ads are off, unsupported or none is ready.
class AdGate {
  const AdGate._();

  static const _validFor = Duration(hours: 24);
  static final Map<String, DateTime> _unlockedAt = {};

  static bool _isUnlocked(String key) {
    final at = _unlockedAt[key];
    return at != null && DateTime.now().difference(at) < _validFor;
  }

  /// Runs [onUnlocked] straight away when no ad is needed, or once the user
  /// has watched one. Declining or skipping the ad does not unlock.
  static Future<void> run(
    BuildContext context,
    WidgetRef ref, {
    required String key,
    required String title,
    required String message,
    required VoidCallback onUnlocked,
    bool interstitialStyle = false,
  }) async {
    if (!ref.read(adsVisibleProvider) || _isUnlocked(key)) {
      onUnlocked();
      return;
    }
    final ready = interstitialStyle
        ? (AdService.rewardedInterstitialReady ||
            AdService.rewardedReady ||
            AdService.interstitialReady)
        : (AdService.rewardedReady ||
            AdService.rewardedInterstitialReady ||
            AdService.interstitialReady);
    if (!ready) {
      onUnlocked();
      return;
    }

    final watch = await AppBottomSheet.confirm(
      context,
      title: title,
      message: message,
      confirmLabel: 'Watch ad',
      cancelLabel: 'Not now',
    );
    if (!watch) return;

    var earned = false;
    void onReward(_) => earned = true;
    void onClosed() {
      if (!earned) return;
      _unlockedAt[key] = DateTime.now();
      onUnlocked();
    }

    final bool shown;
    if (interstitialStyle) {
      if (AdService.rewardedInterstitialReady) {
        shown = AdService.showRewardedInterstitial(
          onReward: onReward,
          onClosed: onClosed,
        );
      } else if (AdService.rewardedReady) {
        shown = AdService.showRewarded(
          onReward: onReward,
          onClosed: onClosed,
        );
      } else if (AdService.interstitialReady) {
        earned = true;
        AdService.showInterstitial(onClosed: onClosed);
        shown = true;
      } else {
        shown = false;
      }
    } else {
      if (AdService.rewardedReady) {
        shown = AdService.showRewarded(
          onReward: onReward,
          onClosed: onClosed,
        );
      } else if (AdService.rewardedInterstitialReady) {
        shown = AdService.showRewardedInterstitial(
          onReward: onReward,
          onClosed: onClosed,
        );
      } else if (AdService.interstitialReady) {
        earned = true;
        AdService.showInterstitial(onClosed: onClosed);
        shown = true;
      } else {
        shown = false;
      }
    }
    if (!shown) onUnlocked();
  }
}
