import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class BoostProfileService {
  static const String _boostKey = 'profile_boost_status';
  static const String _boostExpiryKey = 'profile_boost_expiry';
  static const int boostCost = 30;
  static const double boostDurationHours = 1.5;

  final ApiService _apiService = ApiService();

  BoostProfileService() {
    _apiService.initialize();
  }

  /// Check if user's profile is currently boosted
  Future<bool> isProfileBoosted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boostExpiry = prefs.getString(_boostExpiryKey);
      
      if (boostExpiry == null) return false;
      
      final expiryTime = DateTime.parse(boostExpiry);
      final now = DateTime.now();
      
      return now.isBefore(expiryTime);
    } catch (e) {
      // print('❌ Error checking boost status: $e');
      return false;
    }
  }

  /// Get remaining boost time in hours
  Future<double> getRemainingBoostTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boostExpiry = prefs.getString(_boostExpiryKey);
      
      if (boostExpiry == null) return 0.0;
      
      final expiryTime = DateTime.parse(boostExpiry);
      final now = DateTime.now();
      
      if (now.isAfter(expiryTime)) return 0.0;
      
      final remaining = expiryTime.difference(now);
      return remaining.inMinutes / 60.0; // Return in hours
    } catch (e) {
      // print('❌ Error getting remaining boost time: $e');
      return 0.0;
    }
  }

  /// Purchase a profile boost (temporarily set to 0 credits for debugging)
  Future<Map<String, dynamic>> purchaseBoost() async {
    try {
      // First check current user profile to see credits
      final profileResponse = await _apiService.getMyProfile();
      
      // The credits might be nested in the 'profile' object
      final profileData = profileResponse['profile'] ?? profileResponse;
      final currentCredits = profileData['credits'] ?? 0;
      
      if (currentCredits < boostCost) {
        return {
          'success': false,
          'message': 'Insufficient credits. You need $boostCost credits but have $currentCredits.',
        };
      }

      // Call API to purchase boost
      final response = await _apiService.purchaseProfileBoost();

      if (response['success'] == true) {
        // Store boost status locally
        await _setBoostStatus(true);
        return {
          'success': true,
          'message': 'Profile boosted successfully!',
          'credits': response['credits'] ?? (currentCredits - boostCost),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to purchase boost',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  /// Cancel profile boost
  Future<Map<String, dynamic>> cancelBoost() async {
    try {
      // Call API to cancel boost
      final response = await _apiService.cancelProfileBoost();

      if (response['success'] == true) {
        // Store boost status locally
        await _setBoostStatus(false);
        return {
          'success': true,
          'message': 'Profile boost cancelled successfully!',
          'credits': response['credits'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to cancel boost',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  /// Set boost status locally
  Future<void> _setBoostStatus(bool isBoosted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (isBoosted) {
        final expiryTime = DateTime.now().add(Duration(hours: boostDurationHours.toInt()));
        await prefs.setString(_boostExpiryKey, expiryTime.toIso8601String());
        await prefs.setBool(_boostKey, true);
      } else {
        await prefs.remove(_boostExpiryKey);
        await prefs.setBool(_boostKey, false);
      }
    } catch (e) {
      // print('❌ Error setting boost status: $e');
    }
  }

  /// Get all boosted profiles for the discover page
  Future<List<Map<String, dynamic>>> getBoostedProfiles() async {
    try {
      final profiles = await _apiService.getBoostedProfiles();
      return profiles;
    } catch (e) {
      return [];
    }
  }

  /// Clear expired boost status
  Future<void> clearExpiredBoost() async {
    try {
      final isBoosted = await isProfileBoosted();
      if (!isBoosted) {
        await _setBoostStatus(false);
      }
    } catch (e) {
      // print('❌ Error clearing expired boost: $e');
    }
  }
}
