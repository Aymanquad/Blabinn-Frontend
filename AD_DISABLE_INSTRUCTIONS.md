# Temporarily Disable Ads

## Quick Disable

To temporarily disable all ads in the app, simply change the `adsEnabled` flag in `lib/core/ad_config.dart`:

```dart
// Set this to false to disable all ads temporarily
static const bool adsEnabled = false; // Set to false to disable ads
```

Change it to:

```dart
static const bool adsEnabled = true; // Set to true to enable ads
```

## What Gets Disabled

When `adsEnabled` is set to `false`, the following ad functionality is disabled:

1. **Banner Ads**: All banner ad widgets will be hidden and won't load
2. **Interstitial Ads**: No interstitial ads will be shown or loaded
3. **AdMob SDK**: The AdMob SDK won't be initialized
4. **Ad Timers**: No ad timers will be started
5. **Lifecycle Management**: Ad-related lifecycle management is skipped

## Debug Messages

When ads are disabled, you'll see these debug messages in the console:

- `🚫 Ads are disabled - skipping AdMob initialization`
- `🚫 Ads are disabled - banner ad creation skipped`
- `🚫 Ads are disabled - interstitial ad loading skipped`
- `🚫 Ads are disabled - banner widget hidden`

## Re-enabling Ads

To re-enable ads, simply change the flag back to `true`:

```dart
static const bool adsEnabled = true; // Set to true to enable ads
```

## Benefits

- No network requests to AdMob servers
- No ad-related crashes or errors
- Cleaner app experience during development
- Faster app startup (no ad initialization)
- Reduced data usage

## Files Modified

The following files were modified to support ad disabling:

- `lib/core/ad_config.dart` - Added `adsEnabled` flag
- `lib/services/ad_service.dart` - Added checks for disabled ads
- `lib/widgets/banner_ad_widget.dart` - Added checks for disabled ads
- `lib/widgets/interstitial_ad_manager.dart` - Added checks for disabled ads
