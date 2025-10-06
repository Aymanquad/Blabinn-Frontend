import 'api_service.dart';

/// AI Chatbot Service
/// Handles communication with the AI chatbot fallback system
class AiChatbotService {
  static final AiChatbotService _instance = AiChatbotService._internal();
  factory AiChatbotService() => _instance;
  AiChatbotService._internal();

  final ApiService _apiService = ApiService();

  /// Set user matching state in backend
  /// Called when user starts matching
  Future<Map<String, dynamic>> setMatchingState({
    required String userId,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      print('[AI_CHATBOT] Setting matching state for user: $userId');

      final response =
          await _apiService.postJson('/ai-fallback/set-matching-state', {
        'user_id': userId,
        'preferences': preferences ?? {},
        'start_time': DateTime.now().toIso8601String(),
      });

      if (response['success'] == true) {
        print('[AI_CHATBOT] Matching state set successfully');
        return response;
      } else {
        print(
            '[AI_CHATBOT] Failed to set matching state: ${response['error']}');
        throw Exception(response['error'] ?? 'Failed to set matching state');
      }
    } catch (e) {
      print('[AI_CHATBOT] Error setting matching state: $e');
      rethrow;
    }
  }

  /// Check if AI fallback should be triggered
  /// Called periodically during matching
  Future<Map<String, dynamic>> checkAiFallback({
    required String userId,
  }) async {
    try {
      print('[AI_CHATBOT] Checking AI fallback for user: $userId');

      final response =
          await _apiService.postJson('/ai-fallback/check-ai-fallback', {
        'user_id': userId,
      });

      if (response['success'] == true) {
        if (response['is_ai_match'] == true) {
          print('[AI_CHATBOT] AI fallback triggered for user: $userId');
          print('[AI_CHATBOT] AI user profile: ${response['ai_user_profile']}');
        }
        return response;
      } else {
        print('[AI_CHATBOT] Failed to check AI fallback: ${response['error']}');
        throw Exception(response['error'] ?? 'Failed to check AI fallback');
      }
    } catch (e) {
      print('[AI_CHATBOT] Error checking AI fallback: $e');
      rethrow;
    }
  }

  /// Get AI session data
  /// Called to get current AI session information
  Future<Map<String, dynamic>?> getAiSession({
    required String userId,
  }) async {
    try {
      print('[AI_CHATBOT] Getting AI session for user: $userId');

      final response =
          await _apiService.getJson('/ai-fallback/ai-session/$userId');

      if (response['success'] == true) {
        print('[AI_CHATBOT] AI session retrieved successfully');
        return response['session_data'] as Map<String, dynamic>?;
      } else {
        print('[AI_CHATBOT] No AI session found for user: $userId');
        return null;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error getting AI session: $e');
      return null;
    }
  }

  /// Send message to AI chatbot
  /// Called when user sends a message in AI chat
  Future<Map<String, dynamic>> sendAiMessage({
    required String userId,
    required String sessionId,
    required String message,
  }) async {
    try {
      print('[AI_CHATBOT] Sending message to AI for user: $userId');
      print('[AI_CHATBOT] Message: $message');

      final response =
          await _apiService.postJson('/ai-fallback/send-ai-message', {
        'user_id': userId,
        'message': message,
      });

      if (response['success'] == true) {
        print('[AI_CHATBOT] Message sent to AI successfully');
        return response;
      } else {
        print(
            '[AI_CHATBOT] Failed to send message to AI: ${response['error']}');
        throw Exception(response['error'] ?? 'Failed to send message to AI');
      }
    } catch (e) {
      print('[AI_CHATBOT] Error sending message to AI: $e');
      rethrow;
    }
  }

  /// End AI session
  /// Called when user ends AI chat
  Future<bool> endAiSession({
    required String userId,
  }) async {
    try {
      print('[AI_CHATBOT] Ending AI session for user: $userId');

      final response =
          await _apiService.postJson('/ai-fallback/end-ai-session/$userId', {});

      if (response['success'] == true) {
        print('[AI_CHATBOT] AI session ended successfully');
        return true;
      } else {
        print('[AI_CHATBOT] Failed to end AI session: ${response['error']}');
        return false;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error ending AI session: $e');
      return false;
    }
  }

  /// Clear matching state
  /// Called when user stops matching or gets matched
  Future<bool> clearMatchingState({
    required String userId,
  }) async {
    try {
      print('[AI_CHATBOT] Clearing matching state for user: $userId');

      final response = await _apiService
          .postJson('/ai-fallback/clear-matching-state/$userId', {});

      if (response['success'] == true) {
        print('[AI_CHATBOT] Matching state cleared successfully');
        return true;
      } else {
        print(
            '[AI_CHATBOT] Failed to clear matching state: ${response['error']}');
        return false;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error clearing matching state: $e');
      return false;
    }
  }

  /// Get AI fallback statistics
  /// Called for debugging and monitoring
  Future<Map<String, dynamic>> getStats() async {
    try {
      print('[AI_CHATBOT] Getting AI fallback stats');

      final response = await _apiService.getJson('/ai-fallback/stats');

      if (response['success'] == true) {
        print('[AI_CHATBOT] Stats retrieved successfully');
        return response;
      } else {
        print('[AI_CHATBOT] Failed to get stats: ${response['error']}');
        throw Exception(response['error'] ?? 'Failed to get stats');
      }
    } catch (e) {
      print('[AI_CHATBOT] Error getting stats: $e');
      rethrow;
    }
  }

  /// Configure AI fallback timeout
  /// Called for configuration (admin/debugging purposes)
  Future<bool> configureTimeout({
    required int timeoutSeconds,
  }) async {
    try {
      print('[AI_CHATBOT] Configuring timeout to: $timeoutSeconds seconds');

      final response =
          await _apiService.postJson('/ai-fallback/configure-timeout', {
        'timeout_seconds': timeoutSeconds,
      });

      if (response['success'] == true) {
        print('[AI_CHATBOT] Timeout configured successfully');
        return true;
      } else {
        print('[AI_CHATBOT] Failed to configure timeout: ${response['error']}');
        return false;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error configuring timeout: $e');
      return false;
    }
  }

  /// Check if user is in AI chat
  /// Helper method to determine if current session is AI
  Future<bool> isUserInAiChat({
    required String userId,
  }) async {
    try {
      final sessionData = await getAiSession(userId: userId);
      return sessionData != null;
    } catch (e) {
      print('[AI_CHATBOT] Error checking AI chat status: $e');
      return false;
    }
  }

  /// Get AI user profile from session
  /// Helper method to get AI user profile data
  Future<Map<String, dynamic>?> getAiUserProfile({
    required String userId,
  }) async {
    try {
      final sessionData = await getAiSession(userId: userId);
      if (sessionData != null) {
        return sessionData['ai_user_profile'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('[AI_CHATBOT] Error getting AI user profile: $e');
      return null;
    }
  }

  /// Convert AI user profile to User model
  /// Helper method to convert AI profile to User object
  Map<String, dynamic> convertAiProfileToUser(Map<String, dynamic> aiProfile) {
    try {
      return {
        'id': aiProfile['id'],
        'username': aiProfile['username'],
        'email': null,
        'bio': aiProfile['bio'],
        'profileImage': aiProfile['profile_image'],
        'interests':
            (aiProfile['interests'] as List<dynamic>?)?.cast<String>() ?? [],
        'language': 'en',
        'location': null,
        'latitude': null,
        'longitude': null,
        'isOnline': aiProfile['is_online'] ?? true,
        'lastSeen': DateTime.parse(aiProfile['last_seen'] as String? ??
            DateTime.now().toIso8601String()),
        'isPremium': false,
        'adsFree': false,
        'credits': 100,
        'createdAt': DateTime.parse(aiProfile['created_at'] as String? ??
            DateTime.now().toIso8601String()),
        'updatedAt': DateTime.now(),
        'isBlocked': false,
        'isFriend': false,
        'deviceId': null,
        'age': aiProfile['age'],
        'gender': aiProfile['gender'],
        'userType': 'ai_chatbot', // Special user type for AI
        'isVerified': false,
        'verificationDate': null,
        'connectCount': 0,
        'pageSwitchCount': 0,
        'lastPageSwitchTime': null,
        'dailyAdViews': 0,
        'lastAdViewDate': null,
        'superLikesUsed': 0,
        'boostsUsed': 0,
        'friendsCount': 0,
        'whoLikedViews': 0,
        'lastWhoLikedViewDate': null,
      };
    } catch (e) {
      print('[AI_CHATBOT] Error converting AI profile to user: $e');
      // Return a default user profile
      return {
        'id': 'ai_user_default',
        'username': 'AI Chat Partner',
        'email': null,
        'bio': 'Ready to chat with you!',
        'profileImage': null,
        'interests': ['chatting', 'meeting new people'],
        'language': 'en',
        'location': null,
        'latitude': null,
        'longitude': null,
        'isOnline': true,
        'lastSeen': DateTime.now(),
        'isPremium': false,
        'adsFree': false,
        'credits': 100,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'isBlocked': false,
        'isFriend': false,
        'deviceId': null,
        'age': 25,
        'gender': 'Other',
        'userType': 'ai_chatbot',
        'isVerified': false,
        'verificationDate': null,
        'connectCount': 0,
        'pageSwitchCount': 0,
        'lastPageSwitchTime': null,
        'dailyAdViews': 0,
        'lastAdViewDate': null,
        'superLikesUsed': 0,
        'boostsUsed': 0,
        'friendsCount': 0,
        'whoLikedViews': 0,
        'lastWhoLikedViewDate': null,
      };
    }
  }
}
