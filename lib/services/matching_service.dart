import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user.dart';

/// Chatify Matching Service
/// Handles user type-based matching and discovery features
class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  final ApiService _apiService = ApiService();

  // ==================== MATCHING COMPATIBILITY ====================

  /// Check if two users can match based on their user types
  Future<Map<String, dynamic>> canUsersMatch(String targetUserId) async {
    try {
      return await _apiService.postJson('/matching/can-match', {
        'targetUserId': targetUserId,
      });
    } catch (e) {
      print('❌ Error checking matching compatibility: $e');
      rethrow;
    }
  }

  // ==================== FRIEND REQUESTS WITH VALIDATION ====================

  /// Send friend request with user type validation
  Future<Map<String, dynamic>> sendFriendRequestWithValidation(
    String toUserId, {
    String? message,
    String? type,
  }) async {
    try {
      return await _apiService.postJson('/matching/send-request', {
        'toUserId': toUserId,
        if (message != null) 'message': message,
        if (type != null) 'type': type,
      });
    } catch (e) {
      print('❌ Error sending friend request with validation: $e');
      rethrow;
    }
  }

  // ==================== POTENTIAL MATCHES ====================

  /// Get potential matches based on user type restrictions
  Future<List<User>> getPotentialMatches({
    String? gender,
    int? minAge,
    int? maxAge,
    String? location,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (gender != null) queryParams['gender'] = gender;
      if (minAge != null) queryParams['minAge'] = minAge.toString();
      if (maxAge != null) queryParams['maxAge'] = maxAge.toString();
      if (location != null) queryParams['location'] = location;

      final query = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final data = await _apiService.getJson('/matching/potential-matches?'+query);

      final matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
      return matches.map((match) => User.fromJson(match)).toList();
    } catch (e) {
      print('❌ Error getting potential matches: $e');
      rethrow;
    }
  }

  // ==================== WHO LIKED YOU ====================

  /// Get "Who Liked You" with user type restrictions
  Future<Map<String, dynamic>> getWhoLikedYou({int limit = 10}) async {
    try {
      final data = await _apiService.getJson('/matching/who-liked-you?limit=$limit');
      return data;
    } catch (e) {
      print('❌ Error getting who liked you: $e');
      rethrow;
    }
  }

  /// Check if user can view "Who Liked You"
  Future<Map<String, dynamic>> canViewWhoLikedYou() async {
    try {
      return await _apiService.getJson('/matching/can-view-who-liked');
    } catch (e) {
      print('❌ Error checking who liked you view permission: $e');
      rethrow;
    }
  }

  // ==================== MATCHING STATISTICS ====================

  /// Get user matching statistics
  Future<Map<String, dynamic>> getMatchingStats() async {
    try {
      return await _apiService.getJson('/matching/stats');
    } catch (e) {
      print('❌ Error getting matching stats: $e');
      rethrow;
    }
  }

  // ==================== INSTANT MATCH ====================

  /// Start an instant match (premium feature)
  Future<Map<String, dynamic>> startInstantMatch() async {
    try {
      return await _apiService.postJson('/matching/instant-match', {});
    } catch (e) {
      print('❌ Error starting instant match: $e');
      rethrow;
    }
  }

  // ==================== LIKES AND SUPER LIKES ====================

  /// Like a user (send friend request)
  Future<Map<String, dynamic>> likeUser(
    String targetUserId, {
    String? message,
  }) async {
    try {
      return await _apiService.postJson('/matching/like', {
        'targetUserId': targetUserId,
        if (message != null) 'message': message,
      });
    } catch (e) {
      print('❌ Error liking user: $e');
      rethrow;
    }
  }

  /// Super like a user (premium feature)
  Future<Map<String, dynamic>> superLikeUser(
    String targetUserId, {
    String? message,
  }) async {
    try {
      return await _apiService.postJson('/matching/super-like', {
        'targetUserId': targetUserId,
        if (message != null) 'message': message,
      });
    } catch (e) {
      print('❌ Error super liking user: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if current user can match with another user type
  bool canCurrentUserMatchWith(User currentUser, String otherUserType) {
    return currentUser.canMatchWith(otherUserType);
  }

  /// Get user type matching rules
  Map<String, List<String>> getUserTypeMatchingRules() {
    return {
      'guest': ['guest'],
      'signed_up_free': ['signed_up_free', 'premium'],
      'premium': ['guest', 'signed_up_free', 'premium'],
    };
  }

  /// Check if user has access to a matching feature
  bool hasMatchingFeatureAccess(User user, String feature) {
    return user.hasFeatureAccess(feature);
  }

  /// Get user's matching capabilities
  Map<String, dynamic> getUserMatchingCapabilities(User user) {
    return {
      'userType': user.userType,
      'userTypeBadge': user.userTypeBadge,
      'canMatchWith': {
        'guest': user.canMatchWith('guest'),
        'signed_up_free': user.canMatchWith('signed_up_free'),
        'premium': user.canMatchWith('premium'),
      },
      'features': {
        'superLikes': user.hasFeatureAccess('super_likes'),
        'unlimitedWhoLiked': user.hasFeatureAccess('unlimited_who_liked'),
        'instantMatch': user.hasFeatureAccess('instant_match'),
        'addFriends': user.hasFeatureAccess('add_friends'),
      },
      'limits': {
        'superLikesUsed': user.superLikesUsed,
        'superLikesLimit': user.isPremiumUser ? 5 : 0,
        'whoLikedViews': user.whoLikedViews,
        'whoLikedLimit': user.isPremiumUser ? -1 : 3, // -1 means unlimited
      },
    };
  }

  /// Format matching error message
  String formatMatchingError(Map<String, dynamic> errorData) {
    final reason = errorData['reason'] ?? 'Unknown error';
    
    switch (reason) {
      case 'User type restriction: guest cannot match with signed_up_free':
        return 'Guest users can only match with other guest users. Sign up to match with more people!';
      case 'User type restriction: guest cannot match with premium':
        return 'Guest users can only match with other guest users. Sign up to match with more people!';
      case 'User type restriction: signed_up_free cannot match with guest':
        return 'Free users cannot match with guest users.';
      case 'User not found':
        return 'User not found.';
      case 'Cannot send request to blocked user':
        return 'Cannot send request to this user.';
      case 'Friend request already sent':
        return 'You have already sent a friend request to this user.';
      case 'Already friends':
        return 'You are already friends with this user.';
      default:
        return 'Unable to send request: $reason';
    }
  }

  /// Get user type explanation for UI
  String getUserTypeExplanation(String userType) {
    switch (userType) {
      case 'guest':
        return 'Guest users can only match with other guest users. Sign up to match with more people!';
      case 'signed_up_free':
        return 'Free users can match with other free and premium users. Upgrade to premium for more features!';
      case 'premium':
        return 'Premium users can match with everyone and have access to all features!';
      default:
        return 'Unknown user type.';
    }
  }

  /// Check if user can use super likes
  bool canUseSuperLike(User user) {
    if (!user.hasFeatureAccess('super_likes')) return false;
    
    final maxSuperLikes = user.isPremiumUser ? 5 : 0;
    return user.superLikesUsed < maxSuperLikes;
  }

  /// Get remaining super likes
  int getRemainingSuperLikes(User user) {
    if (!user.hasFeatureAccess('super_likes')) return 0;
    
    final maxSuperLikes = user.isPremiumUser ? 5 : 0;
    return maxSuperLikes - user.superLikesUsed;
  }

  /// Check if user can view "Who Liked You"
  bool canViewWhoLikedYouLocal(User user) {
    // Premium users with unlimited access
    if (user.isPremiumUser && user.hasFeatureAccess('unlimited_who_liked')) {
      return true;
    }

    // Check daily limit for free users
    final now = DateTime.now();
    final lastViewDate = user.lastWhoLikedViewDate;
    
    // Reset counter if it's a new day
    if (lastViewDate == null || now.difference(lastViewDate).inDays >= 1) {
      return true;
    }

    const maxViews = 3; // Max 3 views per day for free users
    return user.whoLikedViews < maxViews;
  }

  /// Get remaining "Who Liked You" views
  int getRemainingWhoLikedViews(User user) {
    // Premium users with unlimited access
    if (user.isPremiumUser && user.hasFeatureAccess('unlimited_who_liked')) {
      return -1; // Unlimited
    }

    // Check daily limit for free users
    final now = DateTime.now();
    final lastViewDate = user.lastWhoLikedViewDate;
    
    // Reset counter if it's a new day
    if (lastViewDate == null || now.difference(lastViewDate).inDays >= 1) {
      return 3; // Max 3 views per day for free users
    }

    const maxViews = 3; // Max 3 views per day for free users
    return maxViews - user.whoLikedViews;
  }
}
