import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fitness_app/core/theme/theme.dart';
 import 'package:fitness_app/features/progress/providers/progress_stats_provider.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

/// Ads stay out of the way for a new user's first sessions.
const int kAdFreeSessions = 3;

/// True when in-feed ads (banner / native) may be shown right now.
final adsVisibleProvider = Provider<bool>((ref) {
  if (!AdService.supported) return false;
  return ref.watch(progressStatsProvider).totalSessions >= kAdFreeSessions;
});

/// Adaptive banner that sizes itself to [width] and disappears when the
/// load fails. Meant for in-content placement.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BannerAd? _ad;
  int? _loadedWidth;

  Future<void> _load(int width) async {
    _loadedWidth = width;
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Banner failed: $e');
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!ref.watch(adsVisibleProvider)) return const SizedBox.shrink();
    final width = (MediaQuery.sizeOf(context).width - 36).truncate();
    if (_loadedWidth != width) _load(width);
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return _AdFrame(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

/// Native ad styled with the app's tokens. Collapses until loaded, so the
/// feed never shows an empty hole. Kept alive so it isn't reloaded while
/// scrolling.
class AdNative extends ConsumerStatefulWidget {
  const AdNative({super.key, this.small = false});

  final bool small;

  @override
  ConsumerState<AdNative> createState() => _AdNativeState();
}

class _AdNativeState extends ConsumerState<AdNative>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  NativeAd? _ad;
  bool _loaded = false;
  Brightness? _brightness;

  void _load(AppColors c) {
    _ad?.dispose();
    _loaded = false;
    _ad = NativeAd(
      adUnitId: AdIds.native,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.small ? TemplateType.small : TemplateType.medium,
        mainBackgroundColor: c.surface,
        cornerRadius: 14,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: c.accentInk,
          backgroundColor: c.accent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: c.ink,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: c.ink2, size: 12),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: c.ink2, size: 12),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Native failed: $e');
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!ref.watch(adsVisibleProvider)) return const SizedBox.shrink();
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    if (_brightness != brightness) {
      _brightness = brightness;
      _load(colors);
    }
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return _AdFrame(
      child: SizedBox(
        height: widget.small ? 91 : 320,
        child: AdWidget(ad: ad),
      ),
    );
  }
}

/// Bordered card around an ad with a visible "Sponsored" label, inset so the
/// platform view doesn't cover the border.
class _AdFrame extends StatelessWidget {
  const _AdFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Align(heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
