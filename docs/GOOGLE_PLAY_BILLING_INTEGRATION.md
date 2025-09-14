# Google Play Billing Integration

## Overview
This document explains how the Google Play Billing integration works in the app.

## Setup Steps

### 1. Google Play Console Setup
- Create in-app products for credit bundles (Cross Border Pack: 8248-1325-3123-2424):
  - `8248-1325-3123-2424-credits-70` - 70 credits for ₹49
  - `8248-1325-3123-2424-credits-150` - 150 credits for ₹99
  - `8248-1325-3123-2424-credits-400` - 400 credits for ₹249
  - `8248-1325-3123-2424-credits-900` - 900 credits for ₹499
  - `8248-1325-3123-2424-credits-2000` - 2000 credits for ₹999

- Create subscription products (Cross Border Pack: 8248-1325-3123-2424):
  - `8248-1325-3123-2424-premium-weekly` - Weekly premium for ₹299
  - `8248-1325-3123-2424-premium-monthly` - Monthly premium for ₹599
  - `8248-1325-3123-2424-premium-3months` - 3 months premium for ₹1499
  - `8248-1325-3123-2424-premium-6months` - 6 months premium for ₹1999
  - `8248-1325-3123-2424-premium-yearly` - Yearly premium for ₹2500
  - `8248-1325-3123-2424-premium-lifetime` - Lifetime premium for ₹4999

- India Only Pack (1294-4337-1831-7466) - Use same product structure with different prefix if needed

### 2. Flutter Dependencies
The app uses the `in_app_purchase` package:
```yaml
dependencies:
  in_app_purchase: ^3.1.13
```

### 3. Implementation Components

#### BillingService (`lib/services/billing_service.dart`)
- Handles Google Play Billing integration
- Manages product queries and purchases
- Verifies purchases with backend
- Provides purchase status updates

#### CreditShopScreen (`lib/screens/credit_shop_screen.dart`)
- Displays available products from Google Play
- Handles purchase initiation
- Shows loading states and error messages
- Updates UI after successful purchases

#### Backend Integration (`blabbin-backend/src/controllers/billingController.js`)
- Verifies purchases with Google Play Developer API
- Updates user credits and premium status
- Handles subscription management

## Purchase Flow

1. **User taps "Buy" or "Activate"**
   - App calls `BillingService.buyProduct()`
   - Google Play purchase dialog appears

2. **User completes purchase**
   - Google Play processes payment
   - Purchase status updates via stream

3. **Purchase verification**
   - App sends purchase details to backend
   - Backend verifies with Google Play Developer API
   - Backend updates user profile (credits/premium status)

4. **UI update**
   - App refreshes user data from server
   - UI updates to show new credits/premium status
   - Success message displayed

## Testing

### Test Accounts
- Add test accounts in Google Play Console
- Use test credit cards for purchases
- Test both consumable (credits) and subscription purchases

### Debug Mode
- Enable debug logging in `BillingService`
- Check purchase status in Google Play Console
- Monitor backend logs for verification requests

## Error Handling

### Common Issues
1. **Product not found**: Check product IDs match Google Play Console
2. **Purchase verification failed**: Check backend Google Play API setup
3. **Network errors**: Handle offline scenarios gracefully

### User Feedback
- Show loading indicators during purchase
- Display clear error messages
- Provide retry options for failed purchases

## Security Considerations

### Backend Verification
- Always verify purchases server-side
- Use Google Play Developer API
- Store purchase records for audit

### Client Security
- Don't store sensitive purchase data locally
- Use secure communication with backend
- Validate all purchase responses

## Production Checklist

- [ ] All product IDs configured in Google Play Console
- [ ] Backend Google Play API credentials set up
- [ ] Test purchases working with test accounts
- [ ] Error handling implemented
- [ ] Purchase verification working
- [ ] UI updates after successful purchases
- [ ] Ads-free feature working for premium users
- [ ] Daily credit claims working
- [ ] Subscription management working

## Troubleshooting

### Purchase Not Completing
1. Check Google Play Console product status
2. Verify product IDs match exactly
3. Check backend verification logs
4. Ensure user is signed in to Google Play

### Credits Not Updating
1. Check backend purchase verification
2. Verify user profile update logic
3. Check API response handling
4. Monitor user provider updates

### Premium Features Not Working
1. Verify `adsFree` field is set correctly
2. Check premium status in user profile
3. Ensure ads-free logic is implemented
4. Test with different premium plans
