# Interstitial Ads Implementation

## Overview
This implementation adds Google AdMob interstitial ads to your Flutter application that automatically show every 20 seconds.

## Configuration

### Current Mode: DEVELOPMENT
The app is currently configured to use **test ads** for development purposes. This ensures you can test the functionality without affecting your AdMob account or violating any policies.

### AdMob IDs Used (Development Mode)
- **Test App ID**: `ca-app-pub-3940256099942544~3347511713` (Android) / `ca-app-pub-3940256099942544~1458002511` (iOS)
- **Test Interstitial Ad Unit ID**: `ca-app-pub-3940256099942544/1033173712` (Android) / `ca-app-pub-3940256099942544/4411468910` (iOS)

### Production IDs (Ready for Production)
When you're ready to go live, update the following IDs in `lib/core/ad_config.dart`:
- **Production App ID**: `ca-app-pub-5160335418378680~2708057766`
- **Production Interstitial Ad Unit ID**: `ca-app-pub-5160335418378680/6987105743`

### Files Modified

1. **`lib/core/ad_config.dart`**
   - Updated with test AdMob IDs for development
   - Production IDs are commented and ready for production use
   - Added interstitial ad unit IDs for both Android and iOS

2. **`lib/services/ad_service.dart`**
   - Enhanced with interstitial ad functionality
   - Added 20-second timer for automatic ad display
   - Added lifecycle management (pause/resume when app goes to background)

3. **`lib/widgets/interstitial_ad_manager.dart`**
   - New widget that manages interstitial ads
   - Handles app lifecycle changes
   - Automatically initializes ads when app starts

4. **`lib/app.dart`**
   - Integrated InterstitialAdManager widget
   - Added test route for debugging

5. **Android Manifest (`android/app/src/main/AndroidManifest.xml`)**
   - Updated with test AdMob app ID

6. **iOS Info.plist (`ios/Runner/Info.plist`)**
   - Updated with test AdMob app ID

## How It Works

### Automatic Timer
- Ads are automatically shown every 20 seconds
- Timer pauses when app goes to background
- Timer resumes when app comes to foreground

### Ad Loading Strategy
- Ads are pre-loaded in the background
- When an ad is shown, the next ad is automatically loaded
- This ensures smooth user experience

### Lifecycle Management
- Timer pauses when app is backgrounded
- Timer resumes when app is foregrounded
- Prevents ads from showing when app is not active

## Testing

### Test Screen
Access the test screen at route `/test-interstitial` to:
- Manually load interstitial ads
- Manually show interstitial ads
- Control the timer (pause/resume)
- View ad status messages

### Console Logs
Check the console for detailed ad status messages:
- `✅ AdMob SDK initialized successfully`
- `🔄 Loading interstitial ad...`
- `✅ Interstitial ad loaded successfully`
- `🎬 Showing interstitial ad`
- `🔒 Interstitial ad dismissed`

### Development vs Production
- **Development**: Uses test ads that always load and show
- **Production**: Uses real ads from your AdMob account

## Usage

### Automatic Mode (Default)
The ads will automatically show every 20 seconds without any additional code needed.

### Manual Control
```dart
final adService = AdService();

// Load an ad manually
await adService.loadInterstitialAd();

// Show an ad manually
await adService.showInterstitialAd();

// Control the timer
adService.pauseInterstitialTimer();
adService.resumeInterstitialTimer();
```

## Switching to Production

When you're ready to go live:

1. **Update `lib/core/ad_config.dart`**:
   - Uncomment the production IDs
   - Comment out the test IDs

2. **Update Android Manifest**:
   - Change `android:value` to your production app ID

3. **Update iOS Info.plist**:
   - Change the `GADApplicationIdentifier` value to your production app ID

4. **Test thoroughly**:
   - Ensure ads are loading properly
   - Check that your AdMob account is configured correctly

## Troubleshooting

### Common Issues

1. **Ads not showing**
   - Check internet connection
   - Verify AdMob IDs are correct
   - Check console for error messages
   - Ensure app is in foreground

2. **Ads showing too frequently**
   - The 20-second timer is fixed
   - Use pause/resume methods to control timing

3. **Test ads showing instead of real ads**
   - In development mode, this is expected
   - For production, verify you're using production AdMob IDs
   - Check that your AdMob account is properly configured

### Debug Information
- Use the test screen to verify ad functionality
- Check console logs for detailed status
- Verify AdMob initialization in main.dart

## Production Considerations

1. **User Experience**
   - 20-second intervals may be too frequent for some users
   - Consider implementing user preferences for ad frequency
   - Add option to disable ads for premium users

2. **Revenue Optimization**
   - Monitor ad performance in AdMob console
   - Consider A/B testing different ad frequencies
   - Implement ad targeting for better performance

3. **Compliance**
   - Ensure compliance with AdMob policies
   - Test on both Android and iOS devices
   - Verify ad content is appropriate for your app

## Files Created/Modified

### New Files
- `lib/widgets/interstitial_ad_manager.dart`
- `lib/screens/test_interstitial_screen.dart`
- `INTERSTITIAL_ADS_IMPLEMENTATION.md`

### Modified Files
- `lib/core/ad_config.dart`
- `lib/services/ad_service.dart`
- `lib/app.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Next Steps

1. **Test the implementation**
   - Run the app and navigate to `/test-interstitial`
   - Verify test ads are loading and showing correctly
   - Check console logs for any errors

2. **Monitor performance**
   - Test the 20-second timer functionality
   - Verify lifecycle management works correctly

3. **Prepare for production**
   - When ready, switch to production IDs
   - Test with real ads before going live
   - Monitor user feedback about ad frequency 