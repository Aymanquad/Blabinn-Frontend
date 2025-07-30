import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import '../screens/privacy_security_settings_screen.dart';
import '../screens/help_support_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile when returning from other screens
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && _currentUser != null) {
      _loadProfileData();
    }
  }

  Future<void> _checkAuthStatus() async {
    await _authService.initialize();
    await _apiService.initialize();
    
    // Check if we have a logged-in user
    if (_authService.currentUser != null) {
      // Load fresh profile data from API
      await _loadProfileData();
    } else {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileData() async {
    try {
      // Load fresh profile data from API
      final responseData = await _apiService.getMyProfile();
      if (responseData != null && responseData['profile'] != null) {
        final profileData = responseData['profile'];
        final updatedUser = User.fromJson(profileData);
        setState(() {
          _currentUser = updatedUser;
          _isLoading = false;
        });
        //print('✅ Profile loaded successfully for user');
      } else {
        // Fall back to cached user if API fails
        setState(() {
          _currentUser = _authService.currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      //print('❌ Error loading profile: $e');
      // Fall back to cached user if API fails
      setState(() {
        _currentUser = _authService.currentUser;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return _buildLoginPrompt();
    }

    return _buildProfileView();
  }

  Widget _buildLoginPrompt() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access your profile and settings',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final User user = _currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: user.hasProfileImage
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: !user.hasProfileImage
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user.username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            if (user.email != null)
              Text(
                user.email!,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 8),

            // User Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isGuest ? Colors.orange[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user.isGuest ? 'Guest User' : 'Registered User',
                style: TextStyle(
                  color: user.isGuest ? Colors.orange[800] : Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Profile Management
                  ListTile(
                    leading: Icon(Icons.person_outline,
                        color: theme.colorScheme.onSurface),
                    title: Text('Manage Profile',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile-management');
                    },
                  ),

                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.2)),

                  // Account Settings
                  ListTile(
                    leading: Icon(Icons.settings_rounded,
                        color: theme.colorScheme.onSurface),
                    title: Text('Account Settings',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onTap: () {
                      Navigator.pushNamed(context, '/account-settings');
                    },
                  ),

                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.2)),

                  // Privacy Settings
                  ListTile(
                    leading: Icon(Icons.privacy_tip,
                        color: theme.colorScheme.onSurface),
                    title: Text('Privacy & Security',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySecuritySettingsScreen(),
                        ),
                      );
                    },
                  ),

                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.2)),

                  // Help & Support
                  ListTile(
                    leading: Icon(Icons.help_outline,
                        color: theme.colorScheme.onSurface),
                    title: Text('Help & Support',
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleLogout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),

            // Debug Authentication Status
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: _apiService.getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Checking authentication...',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7)));
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ Authenticated',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'User ID: ${snapshot.data}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❌ Not Authenticated',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please sign in to use chat features',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
        // Optionally navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
