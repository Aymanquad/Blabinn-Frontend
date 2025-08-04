import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:async';
import '../core/ad_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  Timer? _interstitialTimer;
  bool _isInterstitialAdLoading = false;
  bool _isInterstitialAdShowing = false;

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK initialized successfully');
      
      // Start the interstitial ad timer
      _startInterstitialTimer();
    } catch (e) {
      debugPrint('❌ Failed to initialize AdMob SDK: $e');
    }
  }

  /// Get the appropriate App ID based on platform
  String get appId {
    if (Platform.isIOS) {
      return AdConfig.iosAppId;
    }
    return AdConfig.androidAppId;
  }

  /// Get the appropriate Banner Ad Unit ID based on platform
  String get bannerAdUnitId {
    if (Platform.isIOS) {
      return AdConfig.iosBannerAdUnitId;
    }
    return AdConfig.androidBannerAdUnitId;
  }

  /// Get the appropriate Interstitial Ad Unit ID based on platform
  String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return AdConfig.iosInterstitialAdUnitId;
    }
    return AdConfig.androidInterstitialAdUnitId;
  }

  /// Create a banner ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: ${error.message}');
          ad.dispose();
        },
        onAdOpened: (ad) {
          debugPrint('🔓 Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('🔒 Banner ad closed');
        },
      ),
    );
  }

  /// Load a banner ad
  Future<BannerAd?> loadBannerAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final bannerAd = createBannerAd();
      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      debugPrint('❌ Failed to load banner ad: $e');
      return null;
    }
  }

  /// Create and load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInterstitialAdLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialAdLoading = true;
    debugPrint('🔄 Loading interstitial ad...');

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoading = false;
            debugPrint('✅ Interstitial ad loaded successfully');
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('🔒 Interstitial ad dismissed');
                _interstitialAd = null;
                _isInterstitialAdShowing = false;
                // Load the next ad
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Interstitial ad failed to show: ${error.message}');
                _interstitialAd = null;
                _isInterstitialAdShowing = false;
                // Load the next ad
                loadInterstitialAd();
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('🔓 Interstitial ad showed');
                _isInterstitialAdShowing = true;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ Interstitial ad failed to load: ${error.message}');
            _isInterstitialAdLoading = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to load interstitial ad: $e');
      _isInterstitialAdLoading = false;
    }
  }

  /// Show interstitial ad if available
  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null && !_isInterstitialAdShowing) {
      try {
        await _interstitialAd!.show();
        debugPrint('🎬 Showing interstitial ad');
      } catch (e) {
        debugPrint('❌ Failed to show interstitial ad: $e');
        _interstitialAd = null;
        _isInterstitialAdShowing = false;
      }
    } else {
      debugPrint('⚠️ No interstitial ad available to show');
    }
  }

  /// Start the interstitial ad timer (20 seconds)
  void _startInterstitialTimer() {
    _interstitialTimer?.cancel();
    _interstitialTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!_isInterstitialAdShowing) {
        showInterstitialAd();
      }
    });
    debugPrint('⏰ Interstitial ad timer started (20 seconds)');
  }

  /// Stop the interstitial ad timer
  void stopInterstitialTimer() {
    _interstitialTimer?.cancel();
    _interstitialTimer = null;
    debugPrint('⏹️ Interstitial ad timer stopped');
  }

  /// Pause the interstitial ad timer (useful when app goes to background)
  void pauseInterstitialTimer() {
    _interstitialTimer?.cancel();
    debugPrint('⏸️ Interstitial ad timer paused');
  }

  /// Resume the interstitial ad timer (useful when app comes to foreground)
  void resumeInterstitialTimer() {
    _startInterstitialTimer();
    debugPrint('▶️ Interstitial ad timer resumed');
  }

  /// Dispose of an ad
  void disposeAd(Ad ad) {
    ad.dispose();
  }

  /// Dispose of all ads and timers
  void dispose() {
    _interstitialTimer?.cancel();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    debugPrint('🗑️ Ad service disposed');
  }
} 