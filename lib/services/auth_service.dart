import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/constants.dart';
import '../core/config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'firebase_auth_service.dart';

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
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _deviceId;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get deviceId => _deviceId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Initialize authentication service
  Future<void> initialize() async {
    try {
      _status = AuthStatus.loading;
      
      // Initialize API service
      await _apiService.initialize();
      
      // Listen to Firebase auth state changes
      _firebaseAuth.authStateChanges.listen((firebaseUser) {
        if (firebaseUser != null) {
          _onFirebaseUserChanged(firebaseUser);
        } else {
          _onFirebaseUserSignedOut();
        }
      });
      
      // Check if user is already signed in
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _onFirebaseUserChanged(firebaseUser);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      await _clearAuth();
    }
  }

  // Handle Firebase user changes
  Future<void> _onFirebaseUserChanged(dynamic firebaseUser) async {
    try {
      _status = AuthStatus.loading;
      _isLoading = true;
      
      // Try to get user profile from backend
      try {
        final profileData = await _apiService.getMyProfile();
        // Backend returns profile data in 'profile' key, not 'user' key
        final profile = profileData['profile'];
        
        // Ensure uid is included in the profile data
        if (profile['uid'] == null) {
          profile['uid'] = firebaseUser.uid;
        }
        
        _currentUser = User.fromJson(profile);
        print('✅ Profile loaded successfully for user');
      } catch (profileError) {
        // If profile doesn't exist, create a basic user from Firebase data
        if (profileError.toString().contains('Profile not found')) {
          print('ℹ️ No profile found, user needs to create one');
          
          // Create a basic user from Firebase auth data
          _currentUser = User(
            id: firebaseUser.uid,
            username: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email,
            profileImage: firebaseUser.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          // Re-throw other errors
          throw profileError;
        }
      }
      
      _isAuthenticated = true;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      
      // Save user data locally
      await _saveUserData();
    } catch (e) {
      print('Error handling Firebase user change: $e');
      _status = AuthStatus.error;
      _isLoading = false;
    }
  }

  // Handle Firebase user sign out
  Future<void> _onFirebaseUserSignedOut() async {
    await _clearAuth();
    _status = AuthStatus.unauthenticated;
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;
    _status = AuthStatus.loading;

    try {
      final result = await _firebaseAuth.signInWithGoogle();
      
      if (result['success'] == true) {
        final userData = result['user'];
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        
        await _saveUserData();
        _isLoading = false;
        
        return AuthResult.success(_currentUser!, isNewUser: result['isNewUser'] ?? false);
      } else {
        _isLoading = false;
        _status = AuthStatus.error;
        return AuthResult.error(result['message'] ?? 'Google sign-in failed');
      }
    } catch (e) {
      _isLoading = false;
      _status = AuthStatus.error;
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;
    _status = AuthStatus.loading;

    try {
      final result = await _firebaseAuth.signInWithApple();
      
      if (result['success'] == true) {
        final userData = result['user'];
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        
        await _saveUserData();
        _isLoading = false;
        
        return AuthResult.success(_currentUser!, isNewUser: result['isNewUser'] ?? false);
      } else {
        _isLoading = false;
        _status = AuthStatus.error;
        return AuthResult.error(result['message'] ?? 'Apple sign-in failed');
      }
    } catch (e) {
      _isLoading = false;
      _status = AuthStatus.error;
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Sign in as guest
  Future<AuthResult> signInAsGuest() async {
    if (_isLoading) return AuthResult.loading();

    _isLoading = true;
    _status = AuthStatus.loading;

    try {
      final result = await _firebaseAuth.signInAsGuest();
      
      if (result['success'] == true) {
        final userData = result['user'];
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        _status = AuthStatus.authenticated;
        
        await _saveUserData();
        _isLoading = false;
        
        return AuthResult.success(_currentUser!, isNewUser: result['isNewUser'] ?? false);
      } else {
        _isLoading = false;
        _status = AuthStatus.error;
        return AuthResult.error(result['message'] ?? 'Guest sign-in failed');
      }
    } catch (e) {
      _isLoading = false;
      _status = AuthStatus.error;
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Logout from backend
      await _apiService.logout();
    } catch (e) {
      print('Backend logout error: $e');
      // Continue with logout even if backend fails
    }
    
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Firebase logout error: $e');
    }
    
    await _clearAuth();
    _status = AuthStatus.unauthenticated;
  }

  // Update user profile
  Future<AuthResult> updateProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) {
      return AuthResult.error('Not authenticated');
    }

    try {
      final updatedData = await _apiService.updateProfile(updates);
      // Backend returns profile data in 'profile' key, not 'user' key
      final profile = updatedData['profile'];
      
      // Ensure uid is included in the profile data
      if (profile['uid'] == null && _currentUser != null) {
        profile['uid'] = _currentUser!.id;
      }
      
      await updateCurrentUser(User.fromJson(profile));
      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // Update current user data
  Future<void> updateCurrentUser(User user) async {
    _currentUser = user;
    await _saveUserData();
  }

  // Save user data to local storage
  Future<void> _saveUserData() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    }
  }

  // Clear authentication data
  Future<void> _clearAuth() async {
    _currentUser = null;
    _isAuthenticated = false;
    _isLoading = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // Get device ID
  Future<void> _getDeviceId() async {
    if (_deviceId != null) return;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      } else {
        _deviceId = 'unknown_device';
      }
    } catch (e) {
      _deviceId = 'device_error_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get error message
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');
      
      // Handle specific error types
      if (message.contains('Rate limit exceeded')) {
        return message; // Return the full rate limit message with retry time
      } else if (message.contains('Google sign-in cancelled')) {
        return 'Sign-in was cancelled';
      } else if (message.contains('Apple sign-in failed')) {
        return 'Apple sign-in failed. Please try again';
      } else if (message.contains('Firebase is not configured')) {
        return 'Firebase configuration missing. Please check your setup';
      } else if (message.contains('Backend authentication failed')) {
        return 'Server authentication failed. Please check your internet connection and try again';
      }
      
      return message;
    }
    return error.toString();
  }

  // Check if user is premium
  // PREMIUM CHECKS DISABLED FOR TESTING - ALWAYS RETURNS TRUE
  bool get isPremium => true; // _currentUser?.isPremium ?? false;

  // Check if user is guest
  bool get isGuest => _currentUser?.email == null || _currentUser?.email?.isEmpty == true;

  // Check if Firebase is available
  bool get isFirebaseAvailable => _firebaseAuth.isFirebaseAvailable;

  // Test backend connection
  Future<bool> testBackendConnection() async {
    try {
      print('🔍 DEBUG: Testing backend connection from AuthService...');
      final result = await _firebaseAuth.testBackendConnection();
      print('🔍 DEBUG: Backend connection test result: ${result['success']}');
      return result['success'] == true;
    } catch (e) {
      print('🔍 DEBUG: Backend connection test failed: $e');
      return false;
    }
  }

  // Test POST request
  Future<bool> testPostRequest() async {
    try {
      print('🔍 DEBUG: Testing POST request from AuthService...');
      final result = await _firebaseAuth.testPostRequest();
      print('🔍 DEBUG: POST request test result: ${result['success']}');
      return result['success'] == true;
    } catch (e) {
      print('🔍 DEBUG: POST request test failed: $e');
      return false;
    }
  }

  // Legacy methods - now throw exceptions since we only use Firebase
  @deprecated
  Future<AuthResult> login(String email, String password) async {
    throw Exception('Use Firebase authentication methods instead');
  }

  @deprecated
  Future<AuthResult> register(String email, String password, String username) async {
    throw Exception('Use Firebase authentication methods instead');
  }

  @deprecated
  Future<AuthResult> loginAsGuest() async {
    return await signInAsGuest();
  }

  @deprecated
  Future<void> refreshToken() async {
    throw Exception('Firebase handles token refresh automatically');
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final bool isLoading;
  final bool isNewUser;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
    this.isLoading = false,
    this.isNewUser = false,
  });

  factory AuthResult.success(User user, {bool isNewUser = false}) {
    return AuthResult._(
      success: true,
      user: user,
      isNewUser: isNewUser,
    );
  }

  factory AuthResult.error(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }

  factory AuthResult.loading() {
    return AuthResult._(
      success: false,
      isLoading: true,
    );
  }
}

// Auth exception class
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
} 