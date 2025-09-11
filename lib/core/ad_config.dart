import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AdConfig {
  // TEMPORARY AD DISABLE FLAG
  // Set this to false to disable all ads temporarily
  static const bool adsEnabled = false; // Set to false to disable ads

  /// Check if ads should be shown for the current user
  /// Returns false if user has premium (ads-free) or if ads are globally disabled
  static bool shouldShowAds(BuildContext context) {
    if (!adsEnabled) return false; // Global ads disabled

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      // Don't show ads if user has premium (ads-free)
      if (user?.adsFree == true) return false;

      return true; // Show ads for non-premium users
    } catch (e) {
      // If we can't access user provider, show ads by default
      return true;
    }
  }

  // DEVELOPMENT MODE - Using Test IDs
  // Test App IDs for development
  // static const String androidAppId =
  //     'ca-app-pub-5160335418378680~2708057766'; // Test App ID
  // static const String iosAppId =
  //     'ca-app-pub-5160335418378680~2656870690'; // Test App ID

  // // Test Banner Ad Unit IDs for development
  // static const String androidBannerAdUnitId =
  //     'ca-app-pub-3940256099942544/6300978111'; // Test Banner Ad Unit ID
  // static const String iosBannerAdUnitId =
  //     'ca-app-pub-3940256099942544/2934735716'; // Test Banner Ad Unit ID
  // // Test Interstitial Ad Unit IDs for development
  // static const String androidInterstitialAdUnitId =
  //     'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial Ad Unit ID
  // static const String iosInterstitialAdUnitId =
  //     'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial Ad Unit ID
  // // Test AdMob Application ID for Android Manifest
  // static const String androidManifestAppId =
  //     'ca-app-pub-3940256099942544~3347511713'; // Test App ID

  // // Test AdMob Application ID for iOS Info.plist
  // static const String iosInfoPlistAppId =
  //     'ca-app-pub-3940256099942544~1458002511'; // Test App ID

  // TEST MODE - Using Google Test IDs for development
  static const String androidAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Google Test App ID
  static const String iosAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Google Test App ID

  // Google Test Banner Ad Unit IDs for development
  static const String androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Google Test Banner Ad Unit ID
  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // Google Test Banner Ad Unit ID

  // Google Test Interstitial Ad Unit IDs for development
  static const String androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Google Test Interstitial Ad Unit ID
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910'; // Google Test Interstitial Ad Unit ID

  // Google Test Rewarded Ad Unit IDs for development
  static const String androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Google Test Rewarded Ad Unit ID
  static const String iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313'; // Google Test Rewarded Ad Unit ID

  // Google Test AdMob Application ID for Android Manifest
  static const String androidManifestAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Google Test App ID

  // Google Test AdMob Application ID for iOS Info.plist
  static const String iosInfoPlistAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Google Test App ID
}
