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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
          children: [
            // Complete Unified Profile Card
            _buildUnifiedProfileCard(user, theme),

            const SizedBox(height: 20),

            // App Version
            _buildAppVersion(theme),

            const SizedBox(height: 20),

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


  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
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

            const SizedBox(height: 16),

            // Status badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusBadge(
                  user.isGuest ? 'Guest' : 'Member',
                  user.isGuest ? Colors.orange : Colors.green,
                  theme,
                ),
                const SizedBox(width: 12),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final currentCredits = userProvider.currentUser?.credits ?? 0;
                    return _buildStatusBadge(
                      '$currentCredits Credits',
                      theme.colorScheme.primary,
                      theme,
                      onTap: () => _navigateToCreditShop(),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Preview Profile Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile-preview');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Preview Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Premium Upgrade Section (only for non-premium users)
            if (!user.isPremium) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              
              // Premium header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Premium',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock exclusive features and unlimited connections',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Premium features list
              Column(
                children: [
                  _buildPremiumFeature(
                    icon: Icons.favorite_rounded,
                    title: 'Unlimited Likes',
                    description: 'Like as many profiles as you want',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeature(
                    icon: Icons.visibility_rounded,
                    title: 'See Who Liked You',
                    description: 'View all your admirers instantly',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeature(
                    icon: Icons.rocket_launch_rounded,
                    title: 'Profile Boosts',
                    description: 'Get more visibility and matches',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Upgrade button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToPremiumUpgrade(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Upgrade Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Settings Section
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            
            // Settings header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Settings items
            _buildSettingsItem(
              icon: Icons.settings_rounded,
              title: 'Account Settings',
              subtitle: 'Manage your account preferences',
              onTap: () => Navigator.pushNamed(context, '/account-settings'),
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'Privacy & Security',
              subtitle: 'Control your privacy settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySecuritySettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportSettingsScreen(),
                  ),
                );
              },
            ),
            if (!user.isVerified) ...[
              _buildSettingsItem(
                icon: Icons.verified_outlined,
                title: 'Get Verified',
                subtitle: 'Increase trust and unlock features',
                onTap: () async {
                  try {
                    final res = await _apiService.requestVerification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification requested')),
                      );
                    }
                  } catch (_) {}
                },
              ),
            ],

            // Action Buttons Section
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            // Boost Profile Button
            FutureBuilder<bool>(
              future: BoostProfileService().isProfileBoosted(),
              builder: (context, snapshot) {
                final isBoosted = snapshot.data ?? false;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showBoostProfileDialog(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isBoosted
                              ? Colors.amber.shade400
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isBoosted ? Colors.amber : AppColors.primary).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isBoosted ? Icons.star : Icons.rocket_launch_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBoosted ? 'Profile Boosted!' : 'Boost Profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (isBoosted) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Logout Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleLogout(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          size: 18,
                          color: Colors.red.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, ThemeData theme, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }


  // Modern Settings Section
  Widget _buildModernSettingsSection(User user, ThemeData theme) {
    return ModernCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.settings_rounded,
            title: 'Account Settings',
            subtitle: 'Manage your account preferences',
            onTap: () => Navigator.pushNamed(context, '/account-settings'),
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy & Security',
            subtitle: 'Control your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySecuritySettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportSettingsScreen(),
                ),
              );
            },
          ),
          if (!user.isVerified) ...[
            _buildSettingsItem(
              icon: Icons.verified_outlined,
              title: 'Get Verified',
              subtitle: 'Increase trust and unlock features',
              onTap: () async {
                try {
                  final res = await _apiService.requestVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification requested')),
                    );
                  }
                } catch (_) {}
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: isHighlighted 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isHighlighted 
                  ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
        title,
                        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
        ),
      ),
                      const SizedBox(height: 2),
                      Text(
        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
                    ],
                  ),
                ),
                Icon(
        Icons.arrow_forward_ios,
        size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // App Version
  Widget _buildAppVersion(ThemeData theme) {
    return Text(
      'Version 1.0.0',
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
