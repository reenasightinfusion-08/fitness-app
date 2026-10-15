import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Loads and shows full-screen ads (interstitial and app open). Banner and native ads are widgets — see
/// BannerAdWidget and NativeAdWidget.
class AdService {
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool _initialized = false;

  static InterstitialAd? _interstitial;
  static AppOpenAd? _appOpen;

  static DateTime? _interstitialAt;
  static DateTime? _appOpenAt;

  static final Set<String> _loading = {};

  static bool _showingFullScreen = false;
  static DateTime? _lastFullScreenAt;
  static int _interstitialTriggers = 0;
  static const _interstitialEvery = 2;

  // Interstitials: spaced out in release, unrestricted while testing.
  static Duration get _interstitialGap =>
      kDebugMode ? Duration.zero : const Duration(minutes: 1);
  // Closing any full-screen ad makes the app resume; this keeps that resume
  // from immediately triggering an app open ad.
  static const _appOpenGap = Duration(seconds: 15);

  static const _maxRetries = 4;
  static const _adMaxAge = Duration(minutes: 55);
  static const _appOpenMaxAge = Duration(hours: 4);

  /// Returns false when the current screen shouldn't get an app open ad
  /// (splash, onboarding, lock screen, etc.). Set by MyApp.
  static bool Function()? appOpenGuard;

  static bool _expired(DateTime? at, Duration maxAge) =>
      at == null || DateTime.now().difference(at) > maxAge;

  static bool _since(Duration gap) =>
      _lastFullScreenAt == null ||
      DateTime.now().difference(_lastFullScreenAt!) > gap;

  static void _retry(String key, int attempt, void Function(int) load) {
    if (attempt >= _maxRetries) return;
    final delay = Duration(seconds: 5 * (1 << attempt));
    Future<void>.delayed(delay, () => load(attempt + 1));
  }

  static Future<bool> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        });
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;
    if (!await _gatherConsent()) return;
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadAppOpen();
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) showAppOpenIfAvailable();
    });
  }

  // ── Interstitial ─────────────────────────────────────────────────────────

  static void loadInterstitial([int attempt = 0]) {
    if (!supported || !_loading.add('interstitial')) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading.remove('interstitial');
          _interstitial = ad;
          _interstitialAt = DateTime.now();
        },
        onAdFailedToLoad: (e) {
          debugPrint('Interstitial failed: $e');
          _loading.remove('interstitial');
          _interstitial = null;
          _retry('interstitial', attempt, loadInterstitial);
        },
      ),
    );
  }

  static bool get _interstitialReady {
    if (_interstitial != null && _expired(_interstitialAt, _adMaxAge)) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    if (_interstitial == null) loadInterstitial();
    return _interstitial != null;
  }

  /// Frequency-capped interstitial for natural breaks: shows on every
  /// [_interstitialEvery]th call (or every call when [force]), and never
  /// right after another full-screen ad. [onClosed] always fires.
  static void maybeShowInterstitial({
    VoidCallback? onClosed,
    bool force = false,
  }) {
    _interstitialTriggers++;
    final due = force || _interstitialTriggers % _interstitialEvery == 0;
    if (!supported ||
        !due ||
        _showingFullScreen ||
        !_since(_interstitialGap) ||
        !_interstitialReady) {
      onClosed?.call();
      return;
    }
    showInterstitial(onClosed: onClosed);
  }

  static void showInterstitial({VoidCallback? onClosed}) {
    final ad = _interstitial;
    if (ad == null) {
      onClosed?.call();
      loadInterstitial();
      return;
    }
    _interstitial = null;
    _show(
      ad,
      setCallback: (cb) => ad.fullScreenContentCallback = cb,
      show: ad.show,
      dispose: ad.dispose,
      reload: loadInterstitial,
      onClosed: onClosed,
    );
  }

  // ── App open ─────────────────────────────────────────────────────────────

  static void loadAppOpen([int attempt = 0]) {
    if (!supported || !_loading.add('appOpen')) return;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loading.remove('appOpen');
          _appOpen = ad;
          _appOpenAt = DateTime.now();
        },
        onAdFailedToLoad: (e) {
          debugPrint('App open failed: $e');
          _loading.remove('appOpen');
          _appOpen = null;
          _retry('appOpen', attempt, loadAppOpen);
        },
      ),
    );
  }

  /// Called when the app returns to the foreground.
  static Future<void> showAppOpenIfAvailable() async {
    if (_showingFullScreen || !_since(_appOpenGap)) return;
    // Let lock-screen navigation settle, then re-check everything.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (_showingFullScreen ||
        !_since(_appOpenGap) ||
        !(appOpenGuard?.call() ?? true)) {
      return;
    }
    final ad = _appOpen;
    if (ad == null) {
      loadAppOpen();
      return;
    }
    if (_expired(_appOpenAt, _appOpenMaxAge)) {
      ad.dispose();
      _appOpen = null;
      loadAppOpen();
      return;
    }
    _appOpen = null;
    _show(
      ad,
      setCallback: (cb) => ad.fullScreenContentCallback = cb,
      show: ad.show,
      dispose: ad.dispose,
      reload: loadAppOpen,
    );
  }

  // ── Shared ───────────────────────────────────────────────────────────────

  static void _show<T extends Ad>(
    T ad, {
    required void Function(FullScreenContentCallback<T>) setCallback,
    required VoidCallback show,
    required VoidCallback dispose,
    required VoidCallback reload,
    VoidCallback? onClosed,
  }) {
    void finish() {
      _showingFullScreen = false;
      _lastFullScreenAt = DateTime.now();
      dispose();
      reload();
      onClosed?.call();
    }

    setCallback(FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        _lastFullScreenAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, e) {
        debugPrint('Ad failed to show: $e');
        finish();
      },
    ));
    show();
  }
}
