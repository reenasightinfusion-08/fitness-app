import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/progress/providers/progress_stats_provider.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

/// Ads are enabled straight away across sections.
const int kAdFreeSessions = 0;

/// True when in-feed ads (banner / native) may be shown right now.
final adsVisibleProvider = Provider<bool>((ref) {
  if (!AdService.supported) return false;
  return ref.watch(progressStatsProvider).totalSessions >= kAdFreeSessions;
});

const int _maxRetries = 3;
const Duration _retryDelay = Duration(seconds: 30);

/// Matches the Google small native template’s width-driven row (+ margins).
double _nativeSmallHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width - 36;
  return (width - 16) / 3.6 + 12;
}

const double _kNativeMediumHeight = 335;

NativeTemplateStyle _appNativeTemplateStyle(
  AppColors c, {
  required bool small,
}) {
  return NativeTemplateStyle(
    templateType: small ? TemplateType.small : TemplateType.medium,
    mainBackgroundColor: c.surface,
    cornerRadius: 8,
    callToActionTextStyle: NativeTemplateTextStyle(
      textColor: c.accentInk,
      backgroundColor: c.accent,
      style: NativeTemplateFontStyle.bold,
      size: small ? 11.5 : 13.0,
    ),
    primaryTextStyle: NativeTemplateTextStyle(
      textColor: c.ink,
      style: NativeTemplateFontStyle.bold,
      size: small ? 13.5 : 15.0,
    ),
    secondaryTextStyle: NativeTemplateTextStyle(
      textColor: c.ink2,
      size: small ? 11.0 : 13.0,
    ),
    tertiaryTextStyle: NativeTemplateTextStyle(
      textColor: c.ink3,
      size: small ? 11.0 : 12.0,
    ),
  );
}

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
  int _failures = 0;

  Future<void> _load(int width) async {
    _loadedWidth = width;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null || !mounted) return;
    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _failures = 0;
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Banner failed: $e');
          ad.dispose();
          if (!mounted) return;
          setState(() => _ad = null);
          _scheduleRetry(() => _loadedWidth = null);
        },
      ),
    )..load();
  }

  void _scheduleRetry(VoidCallback reset) {
    if (++_failures > _maxRetries) return;
    Future<void>.delayed(_retryDelay * _failures, () {
      if (mounted) setState(reset);
    });
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
    return _AdFeedShell(
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
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
  bool _useBannerFallback = false;
  Brightness? _brightness;
  int _failures = 0;

  void _load(AppColors c) {
    _ad?.dispose();
    _loaded = false;
    _useBannerFallback = false;
    _ad = NativeAd(
      adUnitId: AdIds.native,
      request: const AdRequest(),
      nativeTemplateStyle: _appNativeTemplateStyle(c, small: widget.small),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _failures = 0;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Native failed: $e');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _useBannerFallback = true;
          });
          _scheduleRetry(() => _brightness = null);
        },
      ),
    )..load();
  }

  void _scheduleRetry(VoidCallback reset) {
    if (++_failures > _maxRetries) return;
    Future<void>.delayed(_retryDelay * _failures, () {
      if (mounted) setState(reset);
    });
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
    if (_useBannerFallback) return const AdBanner();
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    if (_brightness != brightness) {
      _brightness = brightness;
      _load(colors);
    }
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    final height = widget.small
        ? _nativeSmallHeight(context)
        : _kNativeMediumHeight;
    return _AdFeedShell(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: AdWidget(ad: ad),
      ),
    );
  }
}

/// In-feed ad chrome — same surface, radius, and label treatment as app cards.
class _AdFeedShell extends StatelessWidget {
  const _AdFeedShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
            child: Text(
              'Sponsored',
              style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
            ),
          ),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.card,
              side: BorderSide(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}
