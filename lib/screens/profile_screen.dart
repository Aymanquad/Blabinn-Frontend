import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/boost_profile_service.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../screens/privacy_security_settings_screen.dart';
import '../screens/help_support_settings_screen.dart';
import '../widgets/consistent_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/animated_button.dart';
import '../widgets/credits_display.dart';
import '../screens/credit_shop_screen.dart';

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

      if (responseData['profile'] != null) {
        final profileData = responseData['profile'];

        final updatedUser = User.fromJson(profileData);
        setState(() {
          _currentUser = updatedUser;
          _isLoading = false;
        });
      } else {
        // Fall back to cached user if API fails
        setState(() {
          _currentUser = _authService.currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Silently handle profile loading errors
      // Fall back to cached user if API fails
      setState(() {
        _currentUser = _authService.currentUser;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreditShop() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const CreditShopScreen(),
        ),
      );
      // Refresh profile data when returning from credit shop
      if (mounted) {
        await _loadProfileData();
      }
    } catch (e) {
      // Handle navigation error
      debugPrint('Error navigating to credit shop: $e');
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
      appBar: ConsistentAppBar(
        title: 'Profile',
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Preview profile',
            onPressed: () => Navigator.pushNamed(context, '/profile-preview'),
            icon: const Icon(Icons.remove_red_eye_rounded),
          ),
          const SizedBox(width: 8),
        ],
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
      appBar: ConsistentAppBar(
        title: 'Profile',
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Credits display with tap to navigate to credit shop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: CreditsDisplaySmall(
                onTap: () => _navigateToCreditShop(),
              ),
            ),
          ),
          // Settings icon
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
          children: [
            // Complete Unified Profile Card
            _buildUnifiedProfileCard(user, theme),


            // Debug Authentication Status (only in debug mode)
            if (const bool.fromEnvironment('dart.vm.product') == false)
              _buildDebugStatus(theme),
          ],
        ),
      ),
    );
  }

  void _showBoostProfileDialog() {
    final boostService = BoostProfileService();

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<bool>(
        future: boostService.isProfileBoosted(),
        builder: (context, snapshot) {
          final isBoosted = snapshot.data ?? false;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isBoosted ? Icons.star : Icons.rocket_launch,
                  color: isBoosted ? Colors.amber : const Color(0xFF8B5CF6),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isBoosted ? 'Profile Boosted!' : 'Boost Your Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBoosted) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FutureBuilder<double>(
                            future: boostService.getRemainingBoostTime(),
                            builder: (context, timeSnapshot) {
                              final remainingHours = timeSnapshot.data ?? 0.0;
                              return Text(
                                '${remainingHours.toStringAsFixed(1)} hours remaining',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your profile is currently boosted and will appear at the top of the discover page for other users!',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: const Color(0xFF8B5CF6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Boost Benefits:',
                              style: TextStyle(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Appear at the top of discover page\n• Get 10x more profile views\n• Stand out with golden shine effect\n• Lasts for 24 hours',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cost: 30 Credits',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (!isBoosted)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _purchaseBoost();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Boost Now'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _purchaseBoost() async {
    try {
      final boostService = BoostProfileService();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Purchasing boost...'),
            ],
          ),
        ),
      );

      final result = await boostService.purchaseBoost();

      // Close loading dialog
      Navigator.pop(context);

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the profile data to show updated credits
        await _loadProfileData();

        // Also refresh the UserProvider to update the navbar credits
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final newCredits = result['credits'] as int?;
        print('🔍 DEBUG: ProfileScreen - Boost result credits: $newCredits');
        if (newCredits != null) {
          print(
              '🔍 DEBUG: ProfileScreen - Updating UserProvider credits to: $newCredits');
          userProvider.updateCredits(newCredits);
        } else {
          print('🔍 DEBUG: ProfileScreen - Refreshing credits from server');
          await userProvider.refreshCredits();
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140, // Increased height to prevent overflow
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
              BoxShadow(
                      color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToPremiumUpgrade() async {
    // Navigate to credit shop for premium upgrade
    await _navigateToCreditShop();
  }


  void _showActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Activity'),
        content: const Text(
          'Activity tracking is coming soon! '
          'You\'ll be able to view your recent connections, chats, and interactions here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Unified Profile, Premium, and Settings Card
  Widget _buildUnifiedProfileCard(User user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
          children: [
            // Avatar with modern styling
            LargeProfileAvatar(
              imageUrl: user.hasProfileImage ? user.profileImage : null,
              displayName: user.displayName.isNotEmpty
                  ? user.displayName
                  : user.username,
              onTap: () {
                Navigator.pushNamed(context, '/profile-management');
              },
              showEditIcon: true,
              onEdit: () {
                Navigator.pushNamed(context, '/profile-management');
              },
            ),

            const SizedBox(height: 20),

            // Name and username
            Column(
              children: [
                Text(
                  user.displayName.isNotEmpty ? user.displayName : user.username,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (user.displayName.isNotEmpty && user.username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),


            const SizedBox(height: 20),

            // Action Buttons Grid - All 3 side by side (symmetrical)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.visibility_rounded,
                      title: 'Preview Profile',
                      subtitle: 'See how others view you',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/profile-preview'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                    icon: Icons.rocket_launch_rounded,
                      title: 'Boost Profile',
                      subtitle: 'Get more visibility',
                        color: AppColors.primary,
                      onTap: () => _showBoostProfileDialog(),
                    ),
                          ),
                          const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.star_rounded,
                      title: 'Upgrade Now',
                      subtitle: 'Unlock premium features',
                      color: AppColors.primary,
                      onTap: () => _navigateToPremiumUpgrade(),
                            ),
                          ),
                        ],
                      ),
                    ),

            // Action Buttons Section
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

          ],
        ),
    );
  }






  // Debug Status (only in debug mode)
  Widget _buildDebugStatus(ThemeData theme) {
    return ModernCard(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: _apiService.getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    'Checking authentication...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Authenticated',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
          ),
        ],
      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${snapshot.data}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Not Authenticated',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
