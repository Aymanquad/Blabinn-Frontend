# AdMob Banner Ad Integration Setup

This guide will help you set up Google Banner Ads in your Flutter app.

## 🚀 Quick Setup

### 1. Install Dependencies

Run the following command to install the required dependencies:

```bash
flutter pub get
```

### 2. Update Your AdMob IDs

Open `lib/core/ad_config.dart` and replace the test IDs with your actual AdMob IDs:

```dart
class AdConfig {
  // Replace these with your actual AdMob App IDs
  static const String androidAppId = 'YOUR_ANDROID_APP_ID';
  static const String iosAppId = 'YOUR_IOS_APP_ID';
  
  // Replace these with your actual Banner Ad Unit IDs
  static const String androidBannerAdUnitId = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';
  static const String iosBannerAdUnitId = 'YOUR_IOS_BANNER_AD_UNIT_ID';
  
  // AdMob Application ID for Android Manifest
  static const String androidManifestAppId = 'YOUR_ANDROID_APP_ID';
  
  // AdMob Application ID for iOS Info.plist
  static const String iosInfoPlistAppId = 'YOUR_IOS_APP_ID';
}
```

### 3. Update Android Configuration

Open `android/app/src/main/AndroidManifest.xml` and replace the test App ID:

```xml
<!-- AdMob Application ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_ANDROID_APP_ID"/>
```

### 4. Update iOS Configuration

Open `ios/Runner/Info.plist` and replace the test App ID:

```xml
<!-- AdMob Configuration -->
<key>GADApplicationIdentifier</key>
<string>YOUR_IOS_APP_ID</string>
```

## 📱 How to Get Your AdMob IDs

### 1. Create AdMob Account
- Go to [AdMob Console](https://admob.google.com/)
- Sign in with your Google account
- Create a new app

### 2. Get App IDs
- In AdMob Console, go to "Apps" section
- Create a new app for both Android and iOS
- Copy the App IDs (format: ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy)

### 3. Create Banner Ad Units
- Go to "Ad units" section
- Create a new banner ad unit
- Copy the Ad Unit IDs (format: ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy)

## 🎯 Features Implemented

### ✅ AdMob Integration
- [x] Google Mobile Ads SDK integration
- [x] Banner ad widget with loading states
- [x] Platform-specific ad unit IDs
- [x] Error handling and logging
- [x] Ad lifecycle management

### ✅ Banner Ad Placement
- [x] Home screen banner ad
- [x] Responsive design
- [x] Loading indicators
- [x] Graceful fallback when ads fail to load

### ✅ Configuration
- [x] Centralized ad configuration
- [x] Test IDs for development
- [x] Easy ID replacement for production
- [x] Platform-specific configurations

## 🔧 Files Modified/Created

### New Files:
- `lib/services/ad_service.dart` - AdMob service management
- `lib/widgets/banner_ad_widget.dart` - Reusable banner ad widget
- `lib/core/ad_config.dart` - AdMob configuration
- `ADMOB_SETUP.md` - This setup guide

### Modified Files:
- `pubspec.yaml` - Added google_mobile_ads dependency
- `lib/main.dart` - Added AdMob initialization
- `lib/screens/home_screen.dart` - Integrated banner ad
- `android/app/src/main/AndroidManifest.xml` - Added AdMob App ID
- `ios/Runner/Info.plist` - Added AdMob App ID

## 🧪 Testing

### Test IDs (Current Configuration)
The app is currently configured with Google's test ad IDs:
- Android App ID: `ca-app-pub-3940256099942544~3347511713`
- iOS App ID: `ca-app-pub-3940256099942544~1458002511`
- Android Banner: `ca-app-pub-3940256099942544/6300978111`
- iOS Banner: `ca-app-pub-3940256099942544/2934735716`

These test IDs will show test ads during development.

## 🚀 Production Deployment

### 1. Replace Test IDs
Update all IDs in `lib/core/ad_config.dart` with your production AdMob IDs.

### 2. Update Platform Configurations
Update the App IDs in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### 3. Test on Real Devices
- Test on both Android and iOS devices
- Verify ads are loading correctly
- Check ad performance in AdMob console

## 📊 Monitoring

### AdMob Console
- Monitor ad performance
- Track revenue
- Analyze user engagement
- Set up alerts for ad issues

### Debug Logs
The app includes debug logging for ad events:
- ✅ Ad loaded successfully
- ❌ Ad failed to load
- 🔓 Ad opened
- 🔒 Ad closed

## 🔒 Privacy & Compliance

### GDPR Compliance
- Ensure your privacy policy covers ad usage
- Implement consent management if required
- Follow Google's AdMob policies

### App Store Guidelines
- Follow Apple's App Store guidelines for ads
- Ensure ads don't interfere with app functionality
- Test thoroughly before submission

## 🆘 Troubleshooting

### Common Issues:

1. **Ads not showing**
   - Check internet connection
   - Verify AdMob IDs are correct
   - Ensure app is not in test mode
   - Check AdMob console for account status

2. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Check all dependencies are installed
   - Verify platform configurations

3. **iOS build issues**
   - Ensure iOS deployment target is set correctly
   - Check Info.plist configuration
   - Verify AdMob App ID format

## 📞 Support

If you encounter issues:
1. Check AdMob console for account status
2. Review debug logs in the app
3. Test with different devices
4. Contact AdMob support if needed

## 🎉 Success!

Once configured, your app will display banner ads on the home screen. The ads will:
- Load automatically when the screen opens
- Show loading indicators while loading
- Handle errors gracefully
- Dispose properly when the screen closes

Remember to replace the test IDs with your actual AdMob IDs before publishing to app stores! 