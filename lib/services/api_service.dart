import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/config.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';
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
      _firebaseToken = await _firebaseAuth.getIdToken();
    } catch (e) {
      print('Failed to get Firebase token: $e');
      _firebaseToken = null;
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
    }
    
    return headers;
  }

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers,
      ).timeout(_timeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers,
        body: jsonEncode(data),
      ).timeout(_timeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers,
        body: jsonEncode(data),
      ).timeout(_timeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers,
      ).timeout(_timeout);
      
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      // Handle both direct data and wrapped data responses
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
    }
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

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final response = await _put('/profiles/me', updates);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final response = await _delete('/profiles/me');
    return _handleResponse(response);
  }

  // Profile-specific endpoints
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    final response = await _post('/profiles/check-username', {'username': username});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> profileData) async {
    final response = await _post('/profiles', profileData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    final response = await _get('/profiles/me/stats');
    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> searchProfiles(Map<String, dynamic> searchParams) async {
    final response = await _post('/profiles/search', searchParams);
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['profiles'] ?? []);
  }

  Future<List<String>> getTrendingInterests() async {
    final response = await _get('/profiles/trending-interests');
    final data = _handleResponse(response);
    return List<String>.from(data['interests'] ?? []);
  }

  // Upload methods
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final headers = await _headers;
      headers.remove('Content-Type'); // Let http handle multipart content-type
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/profiles/me/picture'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('profilePicture', imageFile.path));
      
      final response = await request.send().timeout(_timeout);
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseData);
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ?? 'Upload failed');
      }
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
      request.files.add(await http.MultipartFile.fromPath('galleryPicture', imageFile.path));
      
      final response = await request.send().timeout(_timeout);
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseData);
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
    final response = await _put('/profiles/me/gallery/main', {'filename': filename});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeGalleryPicture(String filename) async {
    final response = await _delete('/profiles/me/gallery/$filename');
    return _handleResponse(response);
  }

  // Chat methods (if needed)
  Future<Map<String, dynamic>> getChatRooms() async {
    final response = await _get('/chat/rooms');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createChatRoom(Map<String, dynamic> roomData) async {
    final response = await _post('/chat/rooms', roomData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getChatMessages(String roomId) async {
    final response = await _get('/chat/rooms/$roomId/messages');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendMessage(String roomId, Map<String, dynamic> messageData) async {
    final response = await _post('/chat/rooms/$roomId/messages', messageData);
    return _handleResponse(response);
  }

  // Legacy methods - kept for backward compatibility but not used with Firebase auth
  @deprecated
  Future<Map<String, dynamic>> login(String email, String password) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<Map<String, dynamic>> loginAsGuest(String deviceId) async {
    throw Exception('Use Firebase authentication instead');
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
  Future<List<User>> getFriends() async {
    throw Exception('Use Firebase authentication instead');
  }

  @deprecated
  Future<void> addFriend(String userId) async {
    throw Exception('Use Firebase authentication instead');
  }
} 