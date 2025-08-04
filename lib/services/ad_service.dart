import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import '../core/ad_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK initialized successfully');
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

  /// Dispose of an ad
  void disposeAd(Ad ad) {
    ad.dispose();
  }
} 