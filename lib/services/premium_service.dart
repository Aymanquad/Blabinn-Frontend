import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/premium_popup.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Premium Service
/// Handles premium status checks and operations
class PremiumService {
  /// Check if user has premium and show popup if not
  /// PREMIUM CHECKS DISABLED FOR TESTING - ALWAYS RETURNS TRUE
  static Future<bool> checkPremiumOrShowPopup({
    required BuildContext context,
    required String feature,
    required String description,
    VoidCallback? onBuyPremium,
  }) async {
    // PREMIUM CHECKS DISABLED FOR TESTING - ALWAYS ALLOW ACCESS
    print('🔧 DEBUG: Premium check bypassed for testing - feature: $feature');
    return true;
    
    /* ORIGINAL PREMIUM CHECK CODE - COMMENTED OUT FOR TESTING
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) {
      // User not logged in, show premium popup anyway
      await PremiumPopup.show(
        context: context,
        feature: feature,
        description: description,
        onBuyPremium: onBuyPremium,
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
      onBuyPremium: onBuyPremium,
    );
    
    return false;
    */
  }
  
  /// Check if user has premium without showing popup
  /// PREMIUM CHECKS DISABLED FOR TESTING - ALWAYS RETURNS TRUE
  static bool hasActivePremium(User? user) {
    // PREMIUM CHECKS DISABLED FOR TESTING - ALWAYS ALLOW ACCESS
    print('🔧 DEBUG: Premium status check bypassed for testing - always returning true');
    return true;
    
    /* ORIGINAL PREMIUM CHECK CODE - COMMENTED OUT FOR TESTING
    if (user == null) return false;
    return user.isPremium;
    */
  }
  
  /// Check if user has premium from context
  static bool hasActivePremiumFromContext(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return hasActivePremium(userProvider.currentUser);
  }
  
  /// Show premium popup for profile picture upload
  static Future<bool> checkProfilePictureUpload(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Profile Picture Upload',
      description: 'Upload and customize your profile picture to make your profile more attractive.',
    );
  }
  
  /// Show premium popup for chat image sending
  static Future<bool> checkChatImageSending(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Send Images in Chat',
      description: 'Share photos and images with your friends in conversations.',
    );
  }
  
  /// Show premium popup for gender preferences
  static Future<bool> checkGenderPreferences(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Gender Preferences',
      description: 'Choose your preferred gender for random connections and find the right matches.',
    );
  }
  
  /// Show premium popup for media storage
  static Future<bool> checkMediaStorage(BuildContext context) {
    return checkPremiumOrShowPopup(
      context: context,
      feature: 'Media Storage',
      description: 'Keep your shared images and media files stored safely in your account.',
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
  
  /// Navigate to premium purchase screen
  static void navigateToPremiumPurchase(BuildContext context) {
    // TODO: Implement navigation to premium purchase screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Premium purchase will be implemented here'),
        backgroundColor: Colors.orange,
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
  bool get hasActivePremium => PremiumService.hasActivePremiumFromContext(context);
} 