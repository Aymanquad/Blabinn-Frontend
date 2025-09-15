import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
// Removed unused imports
import '../core/config.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import '../utils/global_error_handler.dart';
// Removed unused imports
import 'firebase_auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConfig.apiUrl;
  final Duration _timeout = AppConfig.apiTimeout;
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  String? _firebaseToken;

  // Initialize the service
  Future<void> initialize() async {
    await _refreshFirebaseToken();
  }

  // Refresh Firebase token
  Future<void> _refreshFirebaseToken() async {
    try {
      Logger.debug('Starting token refresh...');

      // Check if Firebase is available
      if (!_firebaseAuth.isFirebaseAvailable) {
        Logger.warning('Firebase is not available - check configuration');
        return;
      }

      Logger.debug('Firebase is available');

      // Check if user is signed in
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        Logger.debug('No Firebase user found - user not signed in');
        return;
      }

      Logger.debug('Firebase user found: ${currentUser.uid}');
      Logger.debug('User is anonymous: ${currentUser.isAnonymous}');
      Logger.debug('User email: ${currentUser.email}');

      Logger.debug('Getting ID token...');
      _firebaseToken = await _firebaseAuth.getIdToken();

      if (_firebaseToken == null) {
        Logger.warning('Firebase token is null - user may not be authenticated');
      } else {
        Logger.debug('Firebase token retrieved successfully (length: ${_firebaseToken!.length})');
        Logger.debug('Token starts with: ${_firebaseToken!.substring(0, 20)}...');
      }
    } catch (e) {
      Logger.error('Failed to get Firebase token', error: e);
    }
  }

  // Headers with Firebase authentication
  Future<Map<String, String>> get _headers async {
    // Always try to get fresh token
    await _refreshFirebaseToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_firebaseToken != null) {
      headers['Authorization'] = 'Bearer $_firebaseToken';
      Logger.debug('Authorization header added with token');
    } else {
      Logger.warning('No Firebase token available for authorization - request will fail');

      // Multiple retry attempts with different strategies
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          Logger.debug('Retry attempt $attempt - getting fresh token...');
          final retryToken = await _firebaseAuth.getIdToken();
          if (retryToken != null) {
            headers['Authorization'] = 'Bearer $retryToken';
            Logger.debug('Retry attempt $attempt successful - token added');
            break;
          } else {
            Logger.debug('Retry attempt $attempt failed - token is null');
          }
        } catch (e) {
          Logger.error('Retry attempt $attempt failed', error: e);
        }

        // Wait a bit before next attempt
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    }

    return headers;
  }

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint) async {
    try {
      // Check if user is authenticated before making request
      final currentUser = _firebaseAuth.currentUser;
      Logger.debug('Current user: ${currentUser?.uid ?? 'null'}');
      Logger.debug('User is anonymous: ${currentUser?.isAnonymous ?? 'unknown'}');

      if (currentUser == null) {
        Logger.warning('User not authenticated - cannot make authenticated request to $endpoint');
        throw Exception('User not authenticated. Please sign in first.');
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers,
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers,
          )
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        // Handle both direct data and wrapped data responses
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return data['data'];
        }
        return data;
      } catch (e) {
        Logger.error('Failed to parse response JSON', error: e);
        throw Exception('Failed to parse response JSON: $e');
      }
    } else {
      final errorMessage = _getErrorMessage(response);
      Logger.error('HTTP request failed', error: errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// Get a user-friendly error message from HTTP response
  String _getErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      return errorData['message'] ?? errorData['error'] ?? 'Unknown error occurred';
    } catch (e) {
      // If we can't parse the error response, return a generic message
      switch (response.statusCode) {
        case 400:
          return 'Bad request. Please check your input.';
        case 401:
          return 'Authentication required. Please sign in again.';
        case 403:
          return 'Access denied. You don\'t have permission to perform this action.';
        case 404:
          return 'Resource not found.';
        case 408:
          return 'Request timeout. Please try again.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
          return 'Service temporarily unavailable. Please try again later.';
        case 503:
          return 'Service unavailable. Please try again later.';
        default:
          return 'HTTP ${response.statusCode}: ${response.body}';
      }
    }
  }

  // ============== Public helpers for JSON endpoints (for other services) ==============
  Future<Map<String, dynamic>> getJson(String endpointWithQuery) async {
    final response = await _get(endpointWithQuery);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postJson(String endpoint, Map<String, dynamic> data) async {
    final response = await _post(endpoint, data);
    return _handleResponse(response);
  }

  // Authentication methods (these are handled by Firebase now)
  Future<Map<String, dynamic>> verifyAuth() async {
    final response = await _get('/auth/verify');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _post('/auth/logout', {});
    return _handleResponse(response);
  }

  // Profile methods - Updated to match backend endpoints
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _get('/profiles/me');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    final response = await _put('/profiles/me', updates);
    return _handleResponse(response);
  }

  // Update FCM token for push notifications
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      Logger.notification('Updating FCM token: ${fcmToken.substring(0, 20)}...');
      final response = await _put('/auth/fcm-token', {'fcmToken': fcmToken});
      final result = _handleResponse(response);
      Logger.notification('FCM token updated successfully');
      return result;
    } catch (e) {
      Logger.error('Failed to update FCM token', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final response = await _delete('/profiles/me');
    return _handleResponse(response);
  }

  // Profile-specific endpoints
  Future<Map<String, dynamic>> checkUsernameAvailability(
      String username) async {
    final response =
        await _post('/profiles/check-username', {'username': username});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createProfile(
      Map<String, dynamic> profileData) async {
    final response = await _post('/profiles', profileData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    final response = await _get('/profiles/me/stats');
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> searchProfiles(
      Map<String, dynamic> searchParams) async {
    // Convert search params to query string for GET request
    final queryParams = searchParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    final response = await _get('/profiles/search?$queryParams');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['profiles'] ?? []);
  }

  Future<List<String>> getTrendingInterests() async {
    final response = await _get('/profiles/trending-interests');
    final data = _handleResponse(response);
    return List<String>.from(data['interests'] ?? []);
  }

  // Billing / Credits endpoints
  Future<Map<String, dynamic>> getCreditBalance() async {
    final response = await _get('/billing/credits/balance');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> claimDailyCredits() async {
    final response = await _post('/billing/credits/claim-daily', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> grantAdCredits({int amount = 10, String trigger = 'credit_shop_reward'}) async {
    final response = await _post('/billing/credits/grant-ad', {
      'amount': amount,
      'trigger': trigger,
    });
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> spendCredits({
    required int amount,
    required String feature,
  }) async {
    final response = await _post('/billing/credits/spend', {
      'amount': amount,
      'feature': feature,
    });
    return _handleResponse(response);
  }

  // Billing verification (simulated backend verification)
  Future<Map<String, dynamic>> verifyPurchase({
    required String platform, // 'android' | 'ios'
    required String productId, // e.g. 8248-1325-3123-2424-credits-70, 8248-1325-3123-2424-premium-monthly
    required String purchaseType, // 'consumable' | 'subscription'
    String? purchaseToken,
    String? orderId,
  }) async {
    final response = await _post('/billing/verify', {
      'platform': platform,
      'productId': productId,
      'purchaseToken': purchaseToken ?? 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'purchaseType': purchaseType,
      'orderId': orderId ?? 'mock_order_${DateTime.now().millisecondsSinceEpoch}',
    });
    return _handleResponse(response);
  }

  // ============== Verification APIs ==============
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final response = await _get('/verification/status');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> requestVerification() async {
    final response = await _post('/verification/request', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeVerification() async {
    final response = await _post('/verification/complete', {});
    return _handleResponse(response);
  }

  // Clear invalid interests for existing users
  Future<Map<String, dynamic>> clearInvalidInterests() async {
    final response = await _put('/profiles/me', {'interests': []});
    return _handleResponse(response);
  }

  // Upload methods
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      // Use Firebase Storage endpoint like chat images
      final request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/upload/profile-picture'));

      // Add headers
      final headers = await _headers;
      request.headers.addAll(headers);

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // Default
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Fallback
      }

      Logger.debug('Uploading profile picture with content type: $contentType, file: ${imageFile.path}');

      // Add image file with explicit content type
      request.files.add(await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response);
      return data;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<Map<String, dynamic>> addGalleryPicture(File imageFile) async {
    try {
      final headers = await _headers;
      headers.remove('Content-Type');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/profiles/me/gallery'),
      );

      request.headers.addAll(headers);
      request.files.add(
          await http.MultipartFile.fromPath('galleryPicture', imageFile.path));

      final response = await request.send().timeout(_timeout);
      final responseData = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseData);
        // Use _handleResponse logic for consistency
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return data['data'];
        }
        return data;
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<Map<String, dynamic>> loadGallery() async {
    final response = await _get('/profiles/me/gallery');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> setMainPicture(String filename) async {
    final response = await _put('/profiles/me/gallery/$filename/main', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeGalleryPicture(String filename) async {
    final response = await _delete('/profiles/me/gallery/$filename');
    return _handleResponse(response);
  }

  // Connection/Friend Request methods
  Future<Map<String, dynamic>> sendFriendRequest(String toUserId,
      {String? message, String? type}) async {
    final data = {
      'toUserId': toUserId,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
    };
    final response = await _post('/connections/friend-request', data);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> acceptFriendRequest(String connectionId) async {
    final response =
        await _put('/connections/friend-request/$connectionId/accept', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> rejectFriendRequest(String connectionId) async {
    final response =
        await _put('/connections/friend-request/$connectionId/reject', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelFriendRequest(String connectionId) async {
    final response = await _delete('/connections/friend-request/$connectionId');
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final response = await _get('/connections/friend-requests/incoming');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['requests'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getOutgoingFriendRequests() async {
    final response = await _get('/connections/friend-requests/outgoing');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['requests'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await _get('/connections/friends');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['friends'] ?? []);
  }

  Future<Map<String, dynamic>> removeFriend(String friendUserId) async {
    final response = await _delete('/connections/friends/$friendUserId');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getConnectionStatus(String targetUserId) async {
    final response = await _get('/connections/status/$targetUserId');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _get('/profiles/$userId');
    final data = _handleResponse(response);
    return data['profile'] ?? data;
  }

  // Chat methods - Direct friend messaging
  Future<Map<String, dynamic>> sendDirectMessage(
      String receiverId, String content) async {
    try {
      Logger.debug('sendDirectMessage() called');
      Logger.debug('receiverId: $receiverId');
      Logger.debug('content: $content');

      // Check authentication first
      final currentUserId = await getCurrentUserId();
      Logger.debug('currentUserId: $currentUserId');

      if (currentUserId == null) {
        Logger.warning('User not authenticated');
        throw Exception('User not logged in. Please sign in to send messages.');
      }

      final data = {
        'receiverId': receiverId,
        'content': content,
        'messageType': 'text',
      };

      Logger.apiRequest('POST', '/chat/messages', data: data);

      final response = await _post('/chat/messages', data);
      Logger.apiResponse('POST', '/chat/messages', response.statusCode, body: response.body);

      return _handleResponse(response);
    } catch (e) {
      Logger.error('sendDirectMessage error', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChatHistoryWithUser(String userId,
      {int limit = 50, String? beforeMessageId}) async {
    try {
      Logger.debug('getChatHistoryWithUser() called with userId: $userId');
      final queryParams = <String>['limit=$limit'];
      if (beforeMessageId != null) {
        queryParams.add('beforeMessageId=$beforeMessageId');
      }
      // Add a parameter to ensure we get the most recent messages
      queryParams.add('sort=desc');
      
      final endpoint = '/chat/history/$userId?${queryParams.join('&')}';
      final response = await _get(endpoint);
      Logger.apiResponse('GET', endpoint, response.statusCode, body: response.body);

      final result = _handleResponse(response);
      Logger.debug('Processed chat history result: $result');
      return result;
    } catch (e) {
      Logger.error('getChatHistoryWithUser error', error: e);
      rethrow;
    }
  }

  /// Get the latest message for a specific user
  Future<Map<String, dynamic>?> getLatestMessageWithUser(String userId) async {
    try {
      Logger.debug('getLatestMessageWithUser() called with userId: $userId');
      final response = await _get('/chat/latest/$userId');
      Logger.apiResponse('GET', '/chat/latest/$userId', response.statusCode);
      
      if (response.statusCode == 200) {
        final result = _handleResponse(response);
        Logger.debug('Latest message result: $result');
        return result;
      }
      return null;
    } catch (e) {
      Logger.error('getLatestMessageWithUser error', error: e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFriendChatRooms() async {
    final response = await _get('/chat/rooms');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['rooms'] ?? []);
  }

  Future<Map<String, dynamic>> getUnreadMessageCount() async {
    final response = await _get('/chat/unread');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    final response = await _put('/chat/messages/$messageId/read', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markAllMessagesAsRead(String userId) async {
    final response = await _put('/chat/messages/read', {'senderId': userId});
    return _handleResponse(response);
  }

  // Get current user ID from Firebase
  Future<String?> getCurrentUserId() async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      Logger.debug('getCurrentUserId() - User ID: $userId');

      if (userId == null) {
        Logger.warning('No Firebase user found. User might be signed in as guest.');
        // Check if user is signed in as guest
        final user = _firebaseAuth.currentUser;
        if (user != null && user.isAnonymous) {
          Logger.debug('User is anonymous (guest)');
          return user.uid; // Return anonymous user ID
        }
        Logger.warning('User is not signed in at all');
        return null;
      }

      Logger.debug('Firebase user authenticated');
      return userId;
    } catch (e) {
      Logger.error('Error getting current user ID', error: e);
      return null;
    }
  }

  // Legacy chat methods (kept for backward compatibility)
  Future<Map<String, dynamic>> getChatRooms() async {
    final response = await _get('/chat/rooms');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createChatRoom(
      Map<String, dynamic> roomData) async {
    final response = await _post('/chat/rooms', roomData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getChatMessages(String roomId) async {
    final response = await _get('/chat/rooms/$roomId/messages');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendMessage(
      String roomId, Map<String, dynamic> messageData) async {
    final response = await _post('/chat/rooms/$roomId/messages', messageData);
    return _handleResponse(response);
  }

  // Legacy methods - kept for backward compatibility but not used with Firebase auth
  @deprecated
  Future<Map<String, dynamic>> login(String email, String password) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<Map<String, dynamic>> loginAsGuest(String deviceId) async {
    throw Exception('Use Firebase authentication instead');
  }

  // Block/Unblock user methods
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    Logger.debug('Calling getBlockedUsers API...');
    final response = await _get('/profiles/me/blocked');
    Logger.apiResponse('GET', '/profiles/me/blocked', response.statusCode);
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['blockedUsers'] ?? []);
  }

  Future<void> blockUser(String userId) async {
    final response = await _post('/profiles/me/block', {'userId': userId});
    _handleResponse(response);
  }

  Future<void> unblockUser(String userId) async {
    final response = await _post('/profiles/me/unblock', {'userId': userId});
    _handleResponse(response);
  }

  // Notification settings methods
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    final response = await _put('/profiles/me/notification-settings', settings);
    _handleResponse(response);
  }

  // Image upload methods
  Future<String> uploadChatImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/upload/chat-image'));

      // Add headers
      final headers = await _headers;
      request.headers.addAll(headers);

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // Default
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Fallback
      }

      Logger.debug('Uploading image with content type: $contentType, file: ${imageFile.path}');

      // Add image file with explicit content type
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response);
      return data['imageUrl'] as String;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  @deprecated
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  void setAuthToken(String token) {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  void clearAuthToken() {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<User> getCurrentUser() async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<User> getUserById(String userId) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<void> addFriend(String userId) async {
    throw Exception('Use Firebase authentication instead');
  }

  // Random chat methods
  Future<Map<String, dynamic>> getActiveRandomChatSession() async {
    final response = await _get('/connections/random/session/active');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forceClearActiveSession() async {
    final response = await _post('/connections/random/session/clear', {});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> endRandomChatSession(String sessionId,
      {String? reason}) async {
    final data = {
      'sessionId': sessionId,
      if (reason != null) 'reason': reason,
    };
    final response = await _post('/connections/random/session/end', data);
    return _handleResponse(response);
  }

  // Report methods
  Future<Map<String, dynamic>> reportUser(String reportedUserId, String reason, {String? description}) async {
    final data = {
      'reportedUserId': reportedUserId,
      'reason': reason,
      if (description != null && description.isNotEmpty) 'description': description,
    };
    final response = await _post('/reports', data);
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getUserReports(String userId, {String type = 'reported'}) async {
    final response = await _get('/reports/user/$userId?type=$type');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['reports'] ?? []);
  }

  Future<bool> hasUserReported(String reportedUserId) async {
    try {
      final currentUserId = await getCurrentUserId();
      if (currentUserId == null) return false;
      
      final reports = await getUserReports(currentUserId, type: 'reporter');
      return reports.any((report) => report['reportedUserId'] == reportedUserId);
    } catch (e) {
      return false;
    }
  }

  // Boost profile methods
  Future<Map<String, dynamic>> purchaseProfileBoost() async {
    final data = {
      'cost': 30,
      'duration': 1.5,
    };
    final response = await _post('/profiles/boost', data);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelProfileBoost() async {
    final response = await _post('/profiles/boost/cancel', {});
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getBoostedProfiles() async {
    try {
      final response = await _get('/profiles/boosted-profiles');
      final data = _handleResponse(response);
      final profiles = List<Map<String, dynamic>>.from(data['profiles'] ?? []);
      return profiles;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== AD TRACKING METHODS ====================

  /// Update connect count
  Future<void> updateConnectCount(int connectCount) async {
    try {
      final response = await _post('/ad-tracking/connect-count', {
        'connectCount': connectCount,
      });
      _handleResponse(response);
      Logger.ads('Connect count updated: $connectCount');
    } catch (e) {
      Logger.error('Error updating connect count', error: e);
      rethrow;
    }
  }

  /// Update page switch count
  Future<void> updatePageSwitchCount(int pageSwitchCount, DateTime lastPageSwitchTime) async {
    try {
      final response = await _post('/ad-tracking/page-switch-count', {
        'pageSwitchCount': pageSwitchCount,
        'lastPageSwitchTime': lastPageSwitchTime.toIso8601String(),
      });
      _handleResponse(response);
      Logger.ads('Page switch count updated: $pageSwitchCount');
    } catch (e) {
      Logger.error('Error updating page switch count', error: e);
      rethrow;
    }
  }

  /// Update daily ad views
  Future<void> updateDailyAdViews(int dailyAdViews, DateTime lastAdViewDate) async {
    try {
      final response = await _post('/ad-tracking/daily-ad-views', {
        'dailyAdViews': dailyAdViews,
        'lastAdViewDate': lastAdViewDate.toIso8601String(),
      });
      _handleResponse(response);
      Logger.ads('Daily ad views updated: $dailyAdViews');
    } catch (e) {
      Logger.error('Error updating daily ad views', error: e);
      rethrow;
    }
  }

  /// Update who liked views
  Future<void> updateWhoLikedViews(int whoLikedViews, DateTime lastWhoLikedViewDate) async {
    try {
      final response = await _post('/ad-tracking/who-liked-views', {
        'whoLikedViews': whoLikedViews,
        'lastWhoLikedViewDate': lastWhoLikedViewDate.toIso8601String(),
      });
      _handleResponse(response);
      Logger.ads('Who liked views updated: $whoLikedViews');
    } catch (e) {
      Logger.error('Error updating who liked views', error: e);
      rethrow;
    }
  }

  /// Track ad view
  Future<void> trackAdView(String adType, String trigger, Map<String, dynamic>? metadata) async {
    try {
      final response = await _post('/ad-tracking/track-view', {
        'adType': adType,
        'trigger': trigger,
        'metadata': metadata ?? {},
      });
      _handleResponse(response);
      Logger.ads('Ad view tracked: $adType - $trigger');
    } catch (e) {
      Logger.error('Error tracking ad view', error: e);
      rethrow;
    }
  }

  /// Track ad click
  Future<void> trackAdClick(String adType, String trigger, Map<String, dynamic>? metadata) async {
    try {
      final response = await _post('/ad-tracking/track-click', {
        'adType': adType,
        'trigger': trigger,
        'metadata': metadata ?? {},
      });
      _handleResponse(response);
      Logger.ads('Ad click tracked: $adType - $trigger');
    } catch (e) {
      Logger.error('Error tracking ad click', error: e);
      rethrow;
    }
  }

  /// Track reward ad completion
  Future<void> trackRewardAdCompletion(String rewardType, Map<String, dynamic>? rewardData) async {
    try {
      final response = await _post('/ad-tracking/track-reward', {
        'rewardType': rewardType,
        'rewardData': rewardData ?? {},
      });
      _handleResponse(response);
      Logger.ads('Reward ad completion tracked: $rewardType');
    } catch (e) {
      Logger.error('Error tracking reward ad completion', error: e);
      rethrow;
    }
  }

  /// Get user ad statistics
  Future<Map<String, dynamic>> getUserAdStats() async {
    try {
      final response = await _get('/ad-tracking/stats');
      final data = _handleResponse(response);
      return data['data'] ?? {};
    } catch (e) {
      Logger.error('Error getting user ad stats', error: e);
      rethrow;
    }
  }

  /// Check if user can view "Who Liked You"
  Future<Map<String, dynamic>> canViewWhoLikedYou() async {
    try {
      final response = await _get('/ad-tracking/can-view-who-liked');
      final data = _handleResponse(response);
      return data['data'] ?? {};
    } catch (e) {
      Logger.error('Error checking who liked you view', error: e);
      rethrow;
    }
  }

  // ============== Analytics APIs ==============
  Future<void> trackEvent(String type, {Map<String, dynamic>? metadata}) async {
    try {
      final response = await _post('/analytics/track', {
        'type': type,
        'metadata': metadata ?? {},
      });
      _handleResponse(response);
    } catch (e) {
      // Non-fatal
    }
  }

}
