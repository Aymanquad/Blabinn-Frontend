import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/constants.dart';
import '../core/config.dart';
import '../models/user.dart';
import 'api_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _authToken;
  String? _refreshToken;
  String? _deviceId;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  String? get refreshToken => _refreshToken;
  String? get deviceId => _deviceId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Initialize authentication service
  Future<void> initialize() async {
    try {
      _status = AuthStatus.loading;
      
      // Load stored authentication data
      await _loadStoredAuth();
      
      // If we have a token, validate it
      if (_authToken != null) {
        await _validateToken();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      await _clearAuth();
    }
  }

  // Login with email and password
  Future<AuthResult> login(String email, String password) async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;

    try {
      final response = await _apiService.login(email, password);
      
      if (response['user'] != null && response['token'] != null) {
        _currentUser = User.fromJson(response['user']);
        _authToken = response['token'];
        
        await _saveAuthData(response);
        _apiService.setAuthToken(_authToken!);
        
        _isLoading = false;
        return AuthResult.success(_currentUser!);
      } else {
        _isLoading = false;
        return AuthResult.error('Invalid response from server');
      }
    } catch (e) {
      _isLoading = false;
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Register new user
  Future<AuthResult> register(String email, String password, String username) async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;

    try {
      final response = await _apiService.register(email, password, username);
      
      if (response['user'] != null && response['token'] != null) {
        _currentUser = User.fromJson(response['user']);
        _authToken = response['token'];
        
        await _saveAuthData(response);
        _apiService.setAuthToken(_authToken!);
        
        _isLoading = false;
        return AuthResult.success(_currentUser!);
      } else {
        _isLoading = false;
        return AuthResult.error('Registration failed');
      }
    } catch (e) {
      _isLoading = false;
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Login as guest
  Future<AuthResult> loginAsGuest() async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;

    try {
      _status = AuthStatus.loading;
      
      // Get or generate device ID
      await _getDeviceId();
      
      final response = await _apiService.guestLogin(_deviceId!);
      
      if (response['user'] != null && response['token'] != null) {
        _currentUser = User.fromJson(response['user']);
        _authToken = response['token'];
        
        await _saveAuthData(response);
        _apiService.setAuthToken(_authToken!);
        
        _status = AuthStatus.authenticated;
        _isLoading = false;
        return AuthResult.success(_currentUser!);
      } else {
        _isLoading = false;
        return AuthResult.error('Guest login failed');
      }
    } catch (e) {
      _isLoading = false;
      _status = AuthStatus.error;
      throw AuthException('Guest login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearAuth();
      _status = AuthStatus.unauthenticated;
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) {
      return AuthResult.error('Not authenticated');
    }

    try {
      final updatedUser = await _apiService.updateProfile(updates);
      await updateCurrentUser(updatedUser);
      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Refresh authentication token
  Future<void> refreshToken() async {
    if (_refreshToken == null) {
      throw AuthException('No refresh token available');
    }

    try {
      final response = await _apiService.refreshToken(_refreshToken!);
      await _saveAuthData(response);
    } catch (e) {
      // If refresh fails, logout the user
      await logout();
      throw AuthException('Token refresh failed: $e');
    }
  }

  // Check if user is premium
  bool get isPremium => _currentUser?.isPremium ?? false;

  // Check if user is guest
  bool get isGuest => _currentUser?.email == null;

  // Get user's preferred language
  String get preferredLanguage => _currentUser?.preferredLanguage ?? 'en';

  // Save authentication data
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    _authToken = data['token'];
    _refreshToken = data['refreshToken'];
    _currentUser = User.fromJson(data['user']);
    
    await prefs.setString('auth_token', _authToken!);
    await prefs.setString('refresh_token', _refreshToken!);
    await prefs.setString('user_data', json.encode(_currentUser!.toJson()));
    await prefs.setString('device_id', _deviceId ?? '');
  }

  // Load stored authentication data
  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
    _deviceId = prefs.getString('device_id');
    
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        _currentUser = User.fromJson(json.decode(userData));
      } catch (e) {
        // Invalid user data, clear it
        await prefs.remove('user_data');
      }
    }
  }

  // Save current user data
  Future<void> _saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  // Clear authentication data
  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    
    _authToken = null;
    _refreshToken = null;
    _currentUser = null;
    _deviceId = null;
    _isAuthenticated = false;
  }

  // Validate authentication token
  Future<void> _validateToken() async {
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      await _saveCurrentUser(user);
    } catch (e) {
      // Token is invalid, clear auth data
      await _clearAuth();
      throw AuthException('Invalid token');
    }
  }

  // Get or generate device ID
  Future<void> _getDeviceId() async {
    if (_deviceId != null) return;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');

    if (_deviceId == null) {
      try {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          _deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          _deviceId = iosInfo.identifierForVendor;
        } else {
          // Generate a random device ID for other platforms
          _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        }
        
        await prefs.setString('device_id', _deviceId!);
      } catch (e) {
        // Fallback to timestamp-based ID
        _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('device_id', _deviceId!);
      }
    }
  }

  // Check if user can perform premium actions
  bool canPerformPremiumAction(String action) {
    if (isPremium) return true;
    
    // Define which actions require premium
    const premiumActions = {
      'advanced_filters',
      'unlimited_chats',
      'priority_matching',
      'video_calls',
      'location_sharing',
      'file_sharing',
    };
    
    return !premiumActions.contains(action);
  }

  // Get user's subscription status
  Map<String, dynamic> getSubscriptionStatus() {
    return {
      'isPremium': isPremium,
      'isGuest': isGuest,
      'canUseAdvancedFilters': canPerformPremiumAction('advanced_filters'),
      'canUseUnlimitedChats': canPerformPremiumAction('unlimited_chats'),
      'canUsePriorityMatching': canPerformPremiumAction('priority_matching'),
      'canUseVideoCalls': canPerformPremiumAction('video_calls'),
      'canUseLocationSharing': canPerformPremiumAction('location_sharing'),
      'canUseFileSharing': canPerformPremiumAction('file_sharing'),
    };
  }

  // Check if user can connect with another user
  bool canConnectWithUser(User otherUser) {
    if (_currentUser == null) return false;
    
    // Check if either user is blocked
    if (_currentUser!.isBlocked || otherUser.isBlocked) return false;
    
    // Check if either user is reported
    if (_currentUser!.isReported || otherUser.isReported) return false;
    
    // Check if both users are online (for random connections)
    if (!_currentUser!.isOnline || !otherUser.isOnline) return false;
    
    return true;
  }

  // Get user's connection limits
  Map<String, int> getConnectionLimits() {
    if (isPremium) {
      return {
        'maxConnectionsPerHour': 50,
        'maxMessagesPerMinute': 100,
        'maxFriendRequestsPerDay': 200,
      };
    } else {
      return {
        'maxConnectionsPerHour': 10,
        'maxMessagesPerMinute': 20,
        'maxFriendRequestsPerDay': 50,
      };
    }
  }

  // Check if user has reached connection limits
  bool hasReachedLimit(String limitType) {
    // This would typically check against stored usage data
    // For now, return false (no limits reached)
    return false;
  }

  // Get user's privacy settings
  Map<String, bool> getPrivacySettings() {
    // This would typically load from stored preferences
    return {
      'showOnlineStatus': true,
      'showLastSeen': true,
      'showLocation': false,
      'allowFriendRequests': true,
      'allowRandomConnections': true,
      'showProfileToEveryone': true,
    };
  }

  // Update privacy settings
  Future<void> updatePrivacySettings(Map<String, bool> settings) async {
    try {
      await updateProfile({'privacySettings': settings});
    } catch (e) {
      throw AuthException('Failed to update privacy settings: $e');
    }
  }

  // Get user's notification settings
  Map<String, bool> getNotificationSettings() {
    // This would typically load from stored preferences
    return {
      'newMessages': true,
      'friendRequests': true,
      'randomConnections': true,
      'videoCalls': true,
      'systemUpdates': true,
    };
  }

  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      await updateProfile({'notificationSettings': settings});
    } catch (e) {
      throw AuthException('Failed to update notification settings: $e');
    }
  }

  // Update current user
  Future<void> updateCurrentUser(User user) async {
    _currentUser = user;
    await _saveCurrentUser(user);
  }

  // Get error message
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');
      
      if (message.contains('401')) {
        return 'Invalid credentials';
      } else if (message.contains('403')) {
        return 'Access denied';
      } else if (message.contains('404')) {
        return 'User not found';
      } else if (message.contains('409')) {
        return 'User already exists';
      } else if (message.contains('422')) {
        return 'Invalid input data';
      } else if (message.contains('500')) {
        return AppStrings.serverError;
      } else if (message.contains('Network error')) {
        return AppStrings.networkError;
      }
      
      return message;
    }
    
    return AppStrings.unknownError;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final bool isLoading;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
    this.isLoading = false,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, error: error);
  }

  factory AuthResult.loading() {
    return AuthResult._(success: false, isLoading: true);
  }
} 