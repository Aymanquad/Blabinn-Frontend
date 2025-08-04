# AdMob Development Testing Guide

## 🧪 **Testing Ads in Development**

Your app is now configured to use **Google's test ad IDs** for safe development and testing.

### ✅ **Current Configuration (Test IDs):**

**Test App IDs:**

- **Android:** `ca-app-pub-3940256099942544~3347511713`
- **iOS:** `ca-app-pub-3940256099942544~1458002511`

**Test Banner Ad Unit IDs:**

- **Android:** `ca-app-pub-3940256099942544/6300978111`
- **iOS:** `ca-app-pub-3940256099942544/2934735716`

### 🚀 **How to Test:**

1. **Install Dependencies:**

   ```bash
   flutter pub get
   ```

2. **Run the App:**

   ```bash
   flutter run
   ```

3. **Check Debug Logs:**
   You should see these messages:
   ```
   🔍 [AD DEBUG] Current AdMob Configuration:
   ✅ [AD DEBUG] Android App ID is using test ID (valid for development)
   ✅ [AD DEBUG] iOS App ID is using test ID (valid for development)
   ✅ [AD DEBUG] Android Banner Ad Unit ID is using test ID (valid for development)
   ✅ [AD DEBUG] iOS Banner Ad Unit ID is using test ID (valid for development)
   ✅ [AD DEBUG] AdMob configuration is using test IDs for development
   💡 [AD DEBUG] Test ads will be displayed - replace with production IDs for release
   ✅ AdMob SDK initialized successfully
   ✅ Banner ad loaded successfully
   ```

### 📱 **What You'll See:**

**Test Ads Will Display:**

- ✅ **Banner ads** at the bottom of the home screen
- ✅ **Test ad content** (clearly marked as test ads)
- ✅ **No real ads** (safe for development)
- ✅ **No revenue tracking** (won't affect your AdMob account)

**Test Ad Characteristics:**

- Always load successfully
- Show test content
- Safe for development
- Won't violate AdMob policies
- Perfect for UI testing

### 🔍 **Testing Checklist:**

- [ ] App compiles without errors
- [ ] AdMob SDK initializes successfully
- [ ] Banner ad appears on home screen
- [ ] Loading indicator shows briefly
- [ ] Test ad content displays
- [ ] No crashes or errors
- [ ] Debug logs show success messages

### 🎯 **Expected Behavior:**

1. **App Startup:**

   - Debug logs show test ID configuration
   - AdMob SDK initializes successfully

2. **Home Screen:**

   - Banner ad appears at bottom
   - Loading indicator shows briefly
   - Test ad content displays

3. **Ad Interaction:**
   - Test ads are clickable
   - Show test landing pages
   - No real ad network calls

### 🔧 **Files Updated for Testing:**

1. **`lib/core/ad_config.dart`** - Updated to use test IDs
2. **`android/app/src/main/AndroidManifest.xml`** - Test App ID
3. **`ios/Runner/Info.plist`** - Test App ID
4. **`lib/utils/ad_debug_helper.dart`** - Updated validation for test IDs

### 📋 **When Ready for Production:**

When you're ready to publish, simply update these files with your real AdMob IDs:

1. **Update `lib/core/ad_config.dart`:**

   ```dart
   static const String androidAppId = 'YOUR_REAL_ANDROID_APP_ID';
   static const String iosAppId = 'YOUR_REAL_IOS_APP_ID';
   static const String androidBannerAdUnitId = 'YOUR_REAL_ANDROID_BANNER_ID';
   static const String iosBannerAdUnitId = 'YOUR_REAL_IOS_BANNER_ID';
   ```

2. **Update `android/app/src/main/AndroidManifest.xml`:**

   ```xml
   android:value="YOUR_REAL_ANDROID_APP_ID"
   ```

3. **Update `ios/Runner/Info.plist`:**
   ```xml
   <string>YOUR_REAL_IOS_APP_ID</string>
   ```

### 🆘 **Troubleshooting:**

**If ads don't show:**

- Check internet connection
- Verify test IDs are correct
- Check debug logs for errors
- Ensure AdMob SDK initialized

**If app crashes:**

- Check for null check operator errors
- Verify all dependencies installed
- Check platform configurations

**If build fails:**

- Run `flutter clean && flutter pub get`
- Check all dependencies
- Verify platform configurations

### 🎉 **Success Indicators:**

When testing is working correctly:

- ✅ Test ads display properly
- ✅ No crashes or errors
- ✅ Debug logs show success
- ✅ Banner ad integrates well with UI
- ✅ Loading states work correctly

### 💡 **Benefits of Test Ads:**

- **Safe Development:** No risk of policy violations
- **Reliable Testing:** Always load successfully
- **UI Testing:** Perfect for testing ad placement
- **No Revenue Impact:** Won't affect your AdMob account
- **Quick Setup:** No need to create real ad units

You're now ready to test the AdMob integration safely in development! 🚀
