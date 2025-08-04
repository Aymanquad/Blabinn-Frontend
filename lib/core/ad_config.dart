/// AdMob Configuration
///
/// Replace the test IDs below with your actual AdMob IDs:
///
/// 1. Android App ID: Get this from your AdMob console
/// 2. iOS App ID: Get this from your AdMob console
/// 3. Android Banner Ad Unit ID: Create a banner ad unit in AdMob console
/// 4. iOS Banner Ad Unit ID: Create a banner ad unit in AdMob console
/// 5. Android Interstitial Ad Unit ID: Create an interstitial ad unit in AdMob console
/// 6. iOS Interstitial Ad Unit ID: Create an interstitial ad unit in AdMob console
///
/// Test IDs (for development only):
/// - Android App ID: ca-app-pub-3940256099942544~3347511713
/// - iOS App ID: ca-app-pub-3940256099942544~1458002511
/// - Android Banner: ca-app-pub-3940256099942544/6300978111
/// - iOS Banner: ca-app-pub-3940256099942544/2934735716
/// - Android Interstitial: ca-app-pub-3940256099942544/1033173712
/// - iOS Interstitial: ca-app-pub-3940256099942544/4411468910
///
/// Production IDs (for production use):
/// - App ID: ca-app-pub-5160335418378680~2708057766
/// - Interstitial Ad Unit ID: ca-app-pub-5160335418378680/6987105743

class AdConfig {
  // DEVELOPMENT MODE - Using Test IDs
  // Change to production IDs when ready for production
  
  // Test App IDs for development
  static const String androidAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Test App ID
  static const String iosAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Test App ID

  // Test Banner Ad Unit IDs for development
  static const String androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test Banner Ad Unit ID
  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // Test Banner Ad Unit ID

  // Test Interstitial Ad Unit IDs for development
  static const String androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial Ad Unit ID
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial Ad Unit ID

  // Test AdMob Application ID for Android Manifest
  static const String androidManifestAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Test App ID

  // Test AdMob Application ID for iOS Info.plist
  static const String iosInfoPlistAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Test App ID

  // PRODUCTION IDs (Uncomment when ready for production)
  // static const String androidAppId =
  //     'ca-app-pub-5160335418378680~2708057766'; // Production App ID
  // static const String iosAppId =
  //     'ca-app-pub-5160335418378680~2708057766'; // Production App ID
  // static const String androidInterstitialAdUnitId =
  //     'ca-app-pub-5160335418378680/6987105743'; // Production Interstitial Ad Unit ID
  // static const String iosInterstitialAdUnitId =
  //     'ca-app-pub-5160335418378680/6987105743'; // Production Interstitial Ad Unit ID
  // static const String androidManifestAppId =
  //     'ca-app-pub-5160335418378680~2708057766'; // Production App ID
  // static const String iosInfoPlistAppId =
  //     'ca-app-pub-5160335418378680~2708057766'; // Production App ID
}
