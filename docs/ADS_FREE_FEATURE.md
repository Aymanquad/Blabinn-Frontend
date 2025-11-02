# Ads-Free Feature for Premium Users

## Overview
Premium users (both monthly and yearly subscribers) now get an ads-free experience in addition to their other premium benefits.

## Implementation

### Backend Changes
1. **UserProfile Model** (`src/models/UserProfile.js`):
   - Added `adsFree` field (boolean, defaults to false)
   - Added `premiumPlan` field to track subscription type

2. **Billing Controller** (`src/controllers/billingController.js`):
   - When premium subscription is activated, `adsFree` is set to `true`
   - Both monthly and yearly premium plans include ads-free access

### Frontend Changes
1. **User Model** (`lib/models/user.dart`):
   - Added `adsFree` field to track ads-free status
   - Updated `copyWith`, `toJson`, and `fromJson` methods

2. **Ad Configuration** (`lib/core/ad_config.dart`):
   - Added `shouldShowAds(BuildContext context)` method
   - Checks user's premium status to determine if ads should be shown

3. **Credit Shop UI** (`lib/screens/credit_shop_screen.dart`):
   - Updated premium plan descriptions to include "ads-free experience"
   - Premium activation now sets `adsFree: true` locally

## Usage

### Checking if Ads Should Be Shown
```dart
import '../core/ad_config.dart';

// In any widget with BuildContext
if (AdConfig.shouldShowAds(context)) {
  // Show ads
  showBannerAd();
} else {
  // Don't show ads (user has premium)
  // Skip ad display
}
```

### Example Implementation
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your main content
        MyMainContent(),
        
        // Conditional ad display
        if (AdConfig.shouldShowAds(context))
          BannerAdWidget(),
      ],
    );
  }
}
```

## Premium Benefits Summary

### Monthly Premium (₹299/month)
- 120 daily credits (in addition to free 30)
- Media folder access
- Unlimited image sending to friends
- **Ads-free experience**

### Yearly Premium (₹2499/year)
- 300 daily credits (in addition to free 30)
- Media folder access
- Unlimited image sending to friends
- **Ads-free experience**

## Technical Notes
- The `adsFree` status is automatically managed when premium subscriptions are activated
- Non-premium users will continue to see ads as normal
- The feature respects the global `adsEnabled` flag in `AdConfig`
- Premium status is checked in real-time through the user provider
