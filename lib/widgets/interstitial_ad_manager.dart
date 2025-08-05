import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ad_service.dart';
import '../core/ad_config.dart';

class InterstitialAdManager extends StatefulWidget {
  final Widget child;

  const InterstitialAdManager({
    super.key,
    required this.child,
  });

  @override
  State<InterstitialAdManager> createState() => _InterstitialAdManagerState();
}

class _InterstitialAdManagerState extends State<InterstitialAdManager>
    with WidgetsBindingObserver {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adService.dispose();
    super.dispose();
  }

  Future<void> _initializeAds() async {
    // Check if ads are disabled
    if (!AdConfig.adsEnabled) {
      debugPrint('🚫 Ads are disabled - interstitial ad manager skipped');
      return;
    }

    try {
      await _adService.initialize();
      // Load the first interstitial ad
      await _adService.loadInterstitialAd();
    } catch (e) {
      debugPrint('❌ Failed to initialize ads: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Skip lifecycle management if ads are disabled
    if (!AdConfig.adsEnabled) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background - pause the timer
        _adService.pauseInterstitialTimer();
        break;
      case AppLifecycleState.resumed:
        // App came to foreground - resume the timer
        _adService.resumeInterstitialTimer();
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop the timer
        _adService.stopInterstitialTimer();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
