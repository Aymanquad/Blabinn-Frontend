import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  List<User> _friends = [];
  List<User> _blockedUsers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<User> get friends => _friends;
  List<User> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get isPremium => _currentUser?.isPremium ?? false;

  // Initialize provider
  Future<void> initialize() async {
    await _authService.initialize();
    await loadCurrentUser();
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    if (_isLoading) return;

    setLoading(true);
    try {
      _currentUser = await _apiService.getCurrentUser();
      await _loadFriends();
      await _loadBlockedUsers();
      clearError();
    } catch (e) {
      setError('Failed to load user profile: $e');
    } finally {
      setLoading(false);
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    setLoading(true);
    try {
      final user = await _authService.login(email, password);
      _currentUser = user;
      await _loadFriends();
      await _loadBlockedUsers();
      clearError();
      notifyListeners();
      return true;
    } catch (e) {
      setError('Login failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Register user
  Future<bool> register(String username, String email, String password) async {
    setLoading(true);
    try {
      final user = await _authService.register(username, email, password);
      _currentUser = user;
      clearError();
      notifyListeners();
      return true;
    } catch (e) {
      setError('Registration failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Login as guest
  Future<bool> loginAsGuest(String deviceId) async {
    setLoading(true);
    try {
      final user = await _authService.loginAsGuest(deviceId);
      _currentUser = user;
      clearError();
      notifyListeners();
      return true;
    } catch (e) {
      setError('Guest login failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _friends.clear();
      _blockedUsers.clear();
      clearError();
      notifyListeners();
    } catch (e) {
      setError('Logout failed: $e');
    } finally {
      setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;

    setLoading(true);
    try {
      _currentUser = await _apiService.updateProfile(data);
      clearError();
      notifyListeners();
      return true;
    } catch (e) {
      setError('Profile update failed: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Load friends
  Future<void> _loadFriends() async {
    try {
      _friends = await _apiService.getFriends();
      notifyListeners();
    } catch (e) {
      // Don't set error for friends loading failure
      print('Failed to load friends: $e');
    }
  }

  // Load blocked users
  Future<void> _loadBlockedUsers() async {
    try {
      _blockedUsers = await _apiService.getBlockedUsers();
      notifyListeners();
    } catch (e) {
      // Don't set error for blocked users loading failure
      print('Failed to load blocked users: $e');
    }
  }

  // Add friend
  Future<bool> addFriend(String userId) async {
    try {
      await _apiService.addFriend(userId);
      await _loadFriends();
      return true;
    } catch (e) {
      setError('Failed to add friend: $e');
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend(String userId) async {
    try {
      await _apiService.removeFriend(userId);
      await _loadFriends();
      return true;
    } catch (e) {
      setError('Failed to remove friend: $e');
      return false;
    }
  }

  // Block user
  Future<bool> blockUser(String userId) async {
    try {
      await _apiService.blockUser(userId);
      await _loadBlockedUsers();
      return true;
    } catch (e) {
      setError('Failed to block user: $e');
      return false;
    }
  }

  // Unblock user
  Future<bool> unblockUser(String userId) async {
    try {
      await _apiService.unblockUser(userId);
      await _loadBlockedUsers();
      return true;
    } catch (e) {
      setError('Failed to unblock user: $e');
      return false;
    }
  }

  // Check if user is friend
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // Check if user is blocked
  bool isBlocked(String userId) {
    return _blockedUsers.any((blocked) => blocked.id == userId);
  }

  // Get user by ID
  User? getUserById(String userId) {
    if (_currentUser?.id == userId) return _currentUser;
    return _friends.firstWhere(
      (friend) => friend.id == userId,
      orElse: () => _blockedUsers.firstWhere(
        (blocked) => blocked.id == userId,
        orElse: () => throw Exception('User not found'),
      ),
    );
  }

  // Update user online status
  void updateOnlineStatus(bool isOnline) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      notifyListeners();
    }
  }

  // Update user location
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await _apiService.updateLocation(latitude, longitude);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          latitude: latitude,
          longitude: longitude,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      setError('Failed to update location: $e');
      return false;
    }
  }

  // Get nearby users
  Future<List<User>> getNearbyUsers(double radius) async {
    try {
      return await _apiService.getNearbyUsers(radius);
    } catch (e) {
      setError('Failed to get nearby users: $e');
      return [];
    }
  }

  // Get user display name
  String getUserDisplayName() {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.displayName ?? _currentUser!.username ?? 'User';
  }

  // Get user profile image
  String? getUserProfileImage() {
    return _currentUser?.profileImageUrl;
  }

  // Get user language
  String getUserLanguage() {
    return _currentUser?.language ?? 'en';
  }

  // Get user country
  String? getUserCountry() {
    return _currentUser?.country;
  }

  // Get user city
  String? getUserCity() {
    return _currentUser?.city;
  }

  // Get user interests
  List<String> getUserInterests() {
    return _currentUser?.interests ?? [];
  }

  // Check if user has location
  bool get hasLocation {
    return _currentUser?.latitude != null && _currentUser?.longitude != null;
  }

  // Get user location
  Map<String, double>? getUserLocation() {
    if (_currentUser?.latitude != null && _currentUser?.longitude != null) {
      return {
        'latitude': _currentUser!.latitude!,
        'longitude': _currentUser!.longitude!,
      };
    }
    return null;
  }

  // Check if user has completed profile
  bool get hasCompletedProfile {
    if (_currentUser == null) return false;
    
    return _currentUser!.bio != null && 
           _currentUser!.profileImageUrl != null;
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    if (_currentUser == null) return 0.0;
    
    int completedFields = 0;
    int totalFields = 4; // displayName, bio, profileImage, interests
    
    completedFields++;
    if (_currentUser!.bio != null) completedFields++;
    if (_currentUser!.profileImageUrl != null) completedFields++;
    if (_currentUser!.interests.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }

  // Helper methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Validation methods
  bool isValidEmail(String email) {
    return _authService.isValidEmail(email);
  }

  bool isValidPassword(String password) {
    return _authService.isValidPassword(password);
  }

  bool isValidUsername(String username) {
    return _authService.isValidUsername(username);
  }

  List<String> getRegistrationErrors({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _authService.getRegistrationErrors(
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  List<String> getLoginErrors({
    required String email,
    required String password,
  }) {
    return _authService.getLoginErrors(
      email: email,
      password: password,
    );
  }

  // Premium feature checks
  bool canAccessPremiumFeature(String feature) {
    return _authService.canAccessPremiumFeature(feature);
  }

  Future<bool> upgradeToPremium(String paymentMethod) async {
    try {
      await _apiService.upgradeToPremium(paymentMethod);
      await loadCurrentUser(); // Reload user to get updated premium status
      return true;
    } catch (e) {
      setError('Failed to upgrade to premium: $e');
      return false;
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      return await _apiService.getSettings();
    } catch (e) {
      setError('Failed to load settings: $e');
      return {};
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _apiService.updateSettings(settings);
      return true;
    } catch (e) {
      setError('Failed to update settings: $e');
      return false;
    }
  }
} 