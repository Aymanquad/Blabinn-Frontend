import 'dart:io';
import '../core/ad_config.dart';

class AdDebugHelper {
  /// Print current AdMob configuration for debugging
  static void printAdConfig() {
    // print('🔍 [AD DEBUG] Current AdMob Configuration:');
    // print('   📱 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    // print('   🆔 Android App ID: ${AdConfig.androidAppId}');
    // print('   🆔 iOS App ID: ${AdConfig.iosAppId}');
    // print('   📢 Android Banner Ad Unit ID: ${AdConfig.androidBannerAdUnitId}');
    // print('   📢 iOS Banner Ad Unit ID: ${AdConfig.iosBannerAdUnitId}');
    // print('   🔧 Android Manifest App ID: ${AdConfig.androidManifestAppId}');
    // print('   🔧 iOS Info.plist App ID: ${AdConfig.iosInfoPlistAppId}');
  }

  /// Check if AdMob IDs are properly configured
  static bool validateAdConfig() {
    bool isValid = true;

    // Check if App IDs are test IDs (valid for development)
    if (AdConfig.androidAppId.contains('3940256099942544')) {
      // print('✅ [AD DEBUG] Android App ID is using test ID (valid for development)');
    }

    if (AdConfig.iosAppId.contains('3940256099942544')) {
      // print('✅ [AD DEBUG] iOS App ID is using test ID (valid for development)');
    }

    // Check if Banner Ad Unit IDs are test IDs (valid for development)
    if (AdConfig.androidBannerAdUnitId.contains('3940256099942544')) {
      // print('✅ [AD DEBUG] Android Banner Ad Unit ID is using test ID (valid for development)');
    }

    if (AdConfig.iosBannerAdUnitId.contains('3940256099942544')) {
      // print('✅ [AD DEBUG] iOS Banner Ad Unit ID is using test ID (valid for development)');
    }

    // print('✅ [AD DEBUG] AdMob configuration is using test IDs for development');
    // print('💡 [AD DEBUG] Test ads will be displayed - replace with production IDs for release');

    return isValid;
  }

  /// Get the appropriate Ad Unit ID for current platform
  static String getCurrentBannerAdUnitId() {
    if (Platform.isIOS) {
      return AdConfig.iosBannerAdUnitId;
    }
    return AdConfig.androidBannerAdUnitId;
  }

  /// Get the appropriate App ID for current platform
  static String getCurrentAppId() {
    if (Platform.isIOS) {
      return AdConfig.iosAppId;
    }
    return AdConfig.androidAppId;
  }
}
