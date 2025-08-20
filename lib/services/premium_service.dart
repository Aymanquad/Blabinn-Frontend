import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/premium_popup.dart';
import '../providers/user_provider.dart';
import '../screens/premium_purchase_screen.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

/// Premium Service
/// Handles premium status checks and operations
class PremiumService {
  /// Check if user has premium and show popup if not
  static Future<bool> checkPremiumOrShowPopup({
    required BuildContext context,
    required String feature,
    required String description,
    VoidCallback? onBuyPremium,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) {
      // User not logged in, show premium popup anyway
      await PremiumPopup.show(
        context: context,
        feature: feature,
        description: description,
        onBuyPremium: onBuyPremium ?? () => navigateToPremiumPurchase(context),
      );
      return false;
    }
    
    if (user.isPremium) {
      return true;
    }
    
    // User is not premium, show popup
    await PremiumPopup.show(
      context: context,
      feature: feature,
      description: description,
      onBuyPremium: onBuyPremium ?? () => navigateToPremiumPurchase(context),
    );
    
    return false;
  }

  /// Check if user has premium without showing popup
  static bool hasActivePremium(User? user) {
    if (user == null) return false;
    return user.isPremium;
  }

  /// Check if user has premium from context
  static bool hasActivePremiumFromContext(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return hasActivePremium(userProvider.currentUser);
  }

  /// Check if user has enough credits and show popup if not
  static Future<bool> checkCreditsOrShowPopup({
    required BuildContext context,
    required String feature,
    required String description,
    required int requiredCredits,
    VoidCallback? onBuyCredits,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) {
      // User not logged in, show premium popup anyway
      await PremiumPopup.show(
        context: context,
        feature: feature,
        description: '$description\n\nCost: $requiredCredits credits',
        onBuyPremium: onBuyCredits ?? () => navigateToPremiumPurchase(context),
      );
      return false;
    }
    
    // Check if user has premium (premium users get all features for free)
    if (user.isPremium) {
      return true;
    }
    
    // Check if user has enough credits
    if (user.credits >= requiredCredits) {
      // User has enough credits, spend them
      return await spendCredits(context, requiredCredits, feature);
    }
    
    // User doesn't have enough credits, show popup
    await PremiumPopup.show(
      context: context,
      feature: feature,
      description: '$description\n\nCost: $requiredCredits credits\nYou have: ${user.credits} credits',
      onBuyPremium: onBuyCredits ?? () => navigateToPremiumPurchase(context),
    );
    
    return false;
  }

  /// Show premium popup for profile picture upload
  static Future<bool> checkProfilePictureUpload(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Profile Picture Upload',
      description:
          'Upload and customize your profile picture to make your profile more attractive.',
    );
  }

  /// Show premium popup for chat image sending (10 credits)
  static Future<bool> checkChatImageSending(BuildContext context) {
    return checkCreditsOrShowPopup(
      context: context,
      feature: 'Send Images in Chat',
      description: 'Share photos and images with your friends in conversations.',
      requiredCredits: 10,
    );
  }

  /// Show premium popup for gender preferences (20 credits)
  static Future<bool> checkGenderPreferences(BuildContext context) {
    return checkCreditsOrShowPopup(
      context: context,
      feature: 'Gender Preferences',
      description: 'Choose your preferred gender for random connections and find the right matches.',
      requiredCredits: 20,
    );
  }

  /// Show premium popup for media storage
  static Future<bool> checkMediaStorage(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Media Storage',
      description:
          'Keep your shared images and media files stored safely in your account.',
    );
  }

  /// Get premium features list
  static List<String> getPremiumFeatures() {
    return [
      'Upload profile pictures',
      'Send & receive images in chats',
      'Gender preferences for random connections',
      'Store images in media folder',
    ];
  }

  /// Get premium price
  static String getPremiumPrice() {
    return '₹1,500';
  }

  /// Spend credits for a specific feature
  static Future<bool> spendCredits(BuildContext context, int amount, String feature) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) return false;
    
    // Premium users don't spend credits
    if (user.isPremium) return true;
    
    // Check if user has enough credits
    if (user.credits < amount) {
      await PremiumPopup.show(
        context: context,
        feature: feature,
        description: 'You need $amount credits but have ${user.credits} credits.\n\nBuy more credits to continue!',
        onBuyPremium: () => navigateToPremiumPurchase(context),
      );
      return false;
    }
    
    // Show confirmation dialog
    final shouldProceed = await _showCreditConfirmationDialog(context, amount, feature);
    if (!shouldProceed) return false;
    
    // Call backend to deduct credits
    try {
      final result = await _deductCreditsFromBackend(amount, feature);
      if (result != null) {
        // Update local state from server truth if available
        final remaining = (result['remaining'] as int?) ?? (user.credits - amount);
        userProvider.updateCurrentUser(user.copyWith(credits: remaining));
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$amount credits used for $feature'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to deduct credits. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Show confirmation dialog for credit spending
  static Future<bool> _showCreditConfirmationDialog(BuildContext context, int amount, String feature) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Credits'),
        content: Text('This will use $amount credits for $feature. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Use Credits'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Deduct credits from backend
  static Future<Map<String, dynamic>?> _deductCreditsFromBackend(int amount, String feature) async {
    try {
      final api = ApiService();
      final result = await api.spendCredits(amount: amount, feature: feature);
      return result;
    } catch (e) {
      print('Error deducting credits: $e');
      return null;
    }
  }

  /// Navigate to premium purchase screen
  static void navigateToPremiumPurchase(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumPurchaseScreen(),
      ),
    );
  }
}

/// Premium Check Mixin
/// Provides premium checking functionality to widgets
mixin PremiumCheckMixin<T extends StatefulWidget> on State<T> {
  /// Check premium for profile picture upload
  Future<bool> checkProfilePictureUpload() {
    return PremiumService.checkProfilePictureUpload(context);
  }

  /// Check premium for chat image sending
  Future<bool> checkChatImageSending() {
    return PremiumService.checkChatImageSending(context);
  }

  /// Check premium for gender preferences
  Future<bool> checkGenderPreferences() {
    return PremiumService.checkGenderPreferences(context);
  }

  /// Check premium for media storage
  Future<bool> checkMediaStorage() {
    return PremiumService.checkMediaStorage(context);
  }

  /// Check if user has premium
  bool get hasActivePremium =>
      PremiumService.hasActivePremiumFromContext(context);
}
