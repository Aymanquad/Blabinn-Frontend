import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/config.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConfig.apiUrl;
  final String _apiVersion = AppConfig.apiVersion;
  final Duration _timeout = AppConfig.apiTimeout;

  String? _authToken;
  String? _userId;

  // Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
  }

  // Headers
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear auth token
  void clearAuthToken() {
    _authToken = null;
  }

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(AppConstants.connectionTimeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(AppConstants.connectionTimeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(AppConstants.connectionTimeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(AppConstants.connectionTimeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    final data = _handleResponse(response);
    if (data['token'] != null) {
      setAuthToken(data['token']);
    }
    
    return data;
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await _post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });
    
    final data = _handleResponse(response);
    if (data['token'] != null) {
      setAuthToken(data['token']);
    }
    
    return data;
  }

  Future<Map<String, dynamic>> loginAsGuest(String deviceId) async {
    final response = await _post('/auth/guest', {
      'deviceId': deviceId,
    });
    
    final data = _handleResponse(response);
    if (data['token'] != null) {
      setAuthToken(data['token']);
    }
    
    return data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
  }

  Future<void> logout() async {
    await _post('/auth/logout', {});
    clearAuthToken();
  }

  // User methods
  Future<User> getCurrentUser() async {
    final response = await _get('/users/me');
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final response = await _put('/users/me', updates);
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  Future<User> getUserById(String userId) async {
    final response = await _get('/users/$userId');
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  Future<List<User>> getFriends() async {
    final response = await _get('/users/friends');
    final data = _handleResponse(response);
    return (data['friends'] as List)
        .map((user) => User.fromJson(user))
        .toList();
  }

  Future<void> addFriend(String userId) async {
    await _post('/users/friends', {'userId': userId});
  }

  Future<void> removeFriend(String userId) async {
    await _delete('/users/friends/$userId');
  }

  Future<void> blockUser(String userId) async {
    await _post('/users/block', {'userId': userId});
  }

  Future<void> unblockUser(String userId) async {
    await _delete('/users/block/$userId');
  }

  Future<List<User>> getBlockedUsers() async {
    final response = await _get('/users/blocked');
    final data = _handleResponse(response);
    return (data['blocked'] as List)
        .map((user) => User.fromJson(user))
        .toList();
  }

  Future<void> reportUser(String userId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_apiVersion/users/report'),
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'reason': reason,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      throw ApiException('Failed to report user: $e');
    }
  }

  // Chat methods
  Future<List<Chat>> getChats() async {
    final response = await _get('/chats');
    final data = _handleResponse(response);
    return (data['chats'] as List)
        .map((chat) => Chat.fromJson(chat))
        .toList();
  }

  Future<Chat> getChat(String chatId) async {
    final response = await _get('/chats/$chatId');
    final data = _handleResponse(response);
    return Chat.fromJson(data);
  }

  Future<List<Message>> getChatMessages(String chatId, {int? limit, String? before}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (before != null) queryParams['before'] = before;
    
    final uri = Uri.parse('$_baseUrl/chats/$chatId/messages').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    final data = _handleResponse(response);
    return (data['messages'] as List)
        .map((message) => Message.fromJson(message))
        .toList();
  }

  Future<Message> sendMessage(String chatId, String content, {MessageType type = MessageType.text}) async {
    final response = await _post('/chats/$chatId/messages', {
      'content': content,
      'type': type.name,
    });
    
    final data = _handleResponse(response);
    return Message.fromJson(data);
  }

  Future<void> markChatAsRead(String chatId) async {
    await _post('/chats/$chatId/read', {});
  }

  Future<void> deleteChat(String chatId) async {
    await _delete('/chats/$chatId');
  }

  // Connect methods
  Future<Map<String, dynamic>> startMatching(Map<String, dynamic> filters) async {
    final response = await _post('/connect/start', filters);
    return _handleResponse(response);
  }

  Future<void> stopMatching() async {
    await _post('/connect/stop', {});
  }

  Future<Map<String, dynamic>> getMatch() async {
    return await _get('/connect/match');
  }

  Future<Map<String, dynamic>> acceptMatch(String matchId) async {
    final response = await _post('/connect/accept', {'matchId': matchId});
    return _handleResponse(response);
  }

  Future<void> rejectMatch(String matchId) async {
    await _post('/connect/reject', {'matchId': matchId});
  }

  // File upload methods
  Future<String> uploadImage(List<int> imageBytes, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/media/upload'),
      );
      
      request.headers.addAll(_headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseData);
        return data['url'] as String;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  // Location methods
  Future<void> updateLocation(double latitude, double longitude) async {
    await _put('/users/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<User>> getNearbyUsers(double radius) async {
    final response = await _get('/users/nearby?radius=$radius');
    final data = _handleResponse(response);
    return (data['users'] as List)
        .map((user) => User.fromJson(user))
        .toList();
  }

  // Premium methods
  Future<Map<String, dynamic>> getPremiumFeatures() async {
    final response = await _get('/premium/features');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> upgradeToPremium(String paymentMethod) async {
    final response = await _post('/premium/upgrade', {
      'paymentMethod': paymentMethod,
    });
    return _handleResponse(response);
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    return await _get('/users/settings');
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _put('/users/settings', settings);
  }

  ApiException _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return ApiException(data['message'] ?? 'Request failed with status ${response.statusCode}');
    } catch (e) {
      return ApiException('Request failed with status ${response.statusCode}');
    }
  }

  bool get isAuthenticated => _authToken != null;
  String? get authToken => _authToken;
  String? get userId => _userId;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
} 
} 