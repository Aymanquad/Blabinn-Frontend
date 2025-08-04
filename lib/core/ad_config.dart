/// AdMob Configuration
///
/// Replace the test IDs below with your actual AdMob IDs:
///
/// 1. Android App ID: Get this from your AdMob console
/// 2. iOS App ID: Get this from your AdMob console
/// 3. Android Banner Ad Unit ID: Create a banner ad unit in AdMob console
/// 4. iOS Banner Ad Unit ID: Create a banner ad unit in AdMob console
///
/// Test IDs (for development only):
/// - Android App ID: ca-app-pub-3940256099942544~3347511713
/// - iOS App ID: ca-app-pub-3940256099942544~1458002511
/// - Android Banner: ca-app-pub-3940256099942544/6300978111
/// - iOS Banner: ca-app-pub-3940256099942544/2934735716

class AdConfig {
  // Test IDs for development - Replace with your actual AdMob IDs for production
  static const String androidAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Test App ID
  static const String iosAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Test App ID

  // Test Banner Ad Unit IDs for development
  static const String androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test Banner Ad Unit ID
  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // Test Banner Ad Unit ID

  // Test AdMob Application ID for Android Manifest
  static const String androidManifestAppId =
      'ca-app-pub-3940256099942544~3347511713'; // Test App ID

  // Test AdMob Application ID for iOS Info.plist
  static const String iosInfoPlistAppId =
      'ca-app-pub-3940256099942544~1458002511'; // Test App ID
}
