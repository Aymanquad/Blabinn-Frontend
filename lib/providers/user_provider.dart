import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  List<User> _friends = [];
  List<User> _blockedUsers = [];
  String? _error;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  List<User> get friends => _friends;
  List<User> get blockedUsers => _blockedUsers;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Initialize user provider
  Future<void> initialize() async {
    await _authService.initialize();
    await _loadCurrentUser();
    await _loadFriends();
    await _loadBlockedUsers();
  }

  // Load current user
  Future<void> _loadCurrentUser() async {
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    setLoading(true);
    try {
      final result = await _authService.login(email, password);
      _currentUser = result.user;
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

  // Register
  Future<bool> register(String username, String email, String password) async {
    setLoading(true);
    try {
      final result = await _authService.register(username, email, password);
      _currentUser = result.user;
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
  Future<bool> loginAsGuest() async {
    setLoading(true);
    try {
      final result = await _authService.loginAsGuest();
      _currentUser = result.user;
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

  // Logout
  Future<void> logout() async {
      await _authService.logout();
      _currentUser = null;
      _friends.clear();
      _blockedUsers.clear();
      notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;

    setLoading(true);
    try {
      final result = await _authService.updateProfile(data);
      _currentUser = result.user;
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
      // For now, set empty list since getFriends doesn't exist
      _friends = [];
      notifyListeners();
    } catch (e) {
      // Don't set error for friends loading failure
      print('Failed to load friends: $e');
    }
  }

  // Load blocked users
  Future<void> _loadBlockedUsers() async {
    try {
      final blockedUsersData = await _apiService.getBlockedUsers();
      _blockedUsers = blockedUsersData.map((data) => User.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      // Don't set error for blocked users loading failure
      print('Failed to load blocked users: $e');
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

  // Check if user is blocked
  bool isBlocked(String userId) {
    return _blockedUsers.any((blocked) => blocked.id == userId);
  }

  // Get blocked user info
  User? getBlockedUser(String userId) {
    try {
      return _blockedUsers.firstWhere((blocked) => blocked.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Profile helpers
  String? get profileImageUrl => _currentUser?.profileImage;
  String? get fullName => _currentUser?.username;
  String? get email => _currentUser?.email;
  String? get bio => _currentUser?.bio;
  bool get isOnline => _currentUser?.isOnline ?? false;
  bool get isPremium => _currentUser?.isPremium ?? false;
  String? get country => _currentUser?.location;
  String? get city => _currentUser?.location;

  // Get user profile image
  String? getUserProfileImage() {
    return _currentUser?.profileImage;
  }

  // Get user language
  String getUserLanguage() {
    return _currentUser?.language ?? 'en';
  }

  // Get user country
  String? getUserCountry() {
    return _currentUser?.location;
  }

  // Get user city
  String? getUserCity() {
    return _currentUser?.location;
  }

  // Get user interests
  List<String> getUserInterests() {
    return _currentUser?.interests ?? [];
  }

  // Profile completion
  bool get hasProfileImage => _currentUser != null && _currentUser!.profileImage != null;
  bool get hasCompletedProfile => _currentUser != null && _currentUser!.username.isNotEmpty;

  double get profileCompletionPercentage {
    if (_currentUser == null) return 0.0;
    
    int totalFields = 5;
    int completedFields = 0;
    
    if (_currentUser!.username.isNotEmpty) completedFields++;
    if (_currentUser!.email != null && _currentUser!.email!.isNotEmpty) completedFields++;
    if (_currentUser!.bio != null && _currentUser!.bio!.isNotEmpty) completedFields++;
    if (_currentUser!.profileImage != null) completedFields++;
    if (_currentUser!.interests.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }

  // Location methods - simplified since API methods don't exist
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      // TODO: Implement when API method exists
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          latitude: latitude,
          longitude: longitude,
        );
    notifyListeners();
  }
    } catch (e) {
      setError('Failed to update location: $e');
    }
  }

  Future<List<User>> getNearbyUsers(double radius) async {
    try {
      // TODO: Implement when API method exists
      return [];
    } catch (e) {
      setError('Failed to get nearby users: $e');
      return [];
    }
  }

  // Validation methods - simplified since AuthService methods don't exist
  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool isValidUsername(String username) {
    return username.length >= 3;
  }

  List<String> getRegistrationErrors(String username, String email, String password) {
    List<String> errors = [];
    if (!isValidUsername(username)) {
      errors.add('Username must be at least 3 characters long');
    }
    if (!isValidEmail(email)) {
      errors.add('Please enter a valid email address');
    }
    if (!isValidPassword(password)) {
      errors.add('Password must be at least 6 characters long');
    }
    return errors;
  }

  List<String> getLoginErrors(String email, String password) {
    List<String> errors = [];
    if (!isValidEmail(email)) {
      errors.add('Please enter a valid email address');
    }
    if (!isValidPassword(password)) {
      errors.add('Password must be at least 6 characters long');
    }
    return errors;
  }

  bool canAccessPremiumFeature(String feature) {
    return isPremium;
  }

  Future<void> upgradeToPremium(String paymentMethod) async {
    try {
      // TODO: Implement when API method exists
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isPremium: true);
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to upgrade to premium: $e');
    }
  }

  // Settings methods - simplified since API methods don't exist
  Future<Map<String, dynamic>> getSettings() async {
    try {
      // TODO: Implement when API method exists
      return {};
    } catch (e) {
      setError('Failed to get settings: $e');
      return {};
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      // TODO: Implement when API method exists
      notifyListeners();
    } catch (e) {
      setError('Failed to update settings: $e');
    }
  }
} 