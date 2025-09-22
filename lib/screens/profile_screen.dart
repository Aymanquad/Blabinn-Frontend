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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Profile header (avatar + name + badges) ---
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Modern Avatar
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

                const SizedBox(height: 16),

                // **Display name** with better styling
                Builder(
                  builder: (context) {
                    final name = (user.displayName.trim().isNotEmpty)
                        ? user.displayName.trim()
                        : (user.username.trim().isNotEmpty)
                            ? user.username.trim()
                            : 'User';

                    return Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Modern badges under the name
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Original green color
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        user.isGuest ? 'Guest User' : 'Registered User',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final currentCredits =
                            userProvider.currentUser?.credits ?? 0;
                        return GestureDetector(
                          onTap: () => _navigateToCreditShop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Credits: $currentCredits',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Profile Preview Button with Animation
                Center(
                  child: AnimatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile-preview');
                    },
                    child: OutlinedButton(
                      onPressed: null, // Handled by AnimatedButton
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preview Profile',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Premium Recommendation Section (only for non-premium users)
            if (!user.isPremium) ...[
              _buildPremiumRecommendationCard(user),
              const SizedBox(height: 16),
            ],

            // Quick Actions Section
            _buildQuickActionsSection(theme),

            const SizedBox(height: 16),

            // Settings Section with Modern Card
            ModernCard(
              child: Column(
                children: [
                  // Verification CTA
                  if (!user.isVerified) ...[
                    ListTile(
                      leading: Icon(Icons.verified_outlined,
                          color: const Color(0xFF8B5CF6)),
                      title: Text('Get Verified',
                          style: TextStyle(color: theme.colorScheme.onSurface)),
                      subtitle: Text(
                          'Increase trust and unlock features in some regions'),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      onTap: () async {
                        try {
                          final res = await _apiService.requestVerification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Verification requested')),
                            );
                          }
                        } catch (_) {}
                      },
                    ),
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withOpacity(0.2)),
                  ],
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
                          builder: (context) =>
                              const PrivacySecuritySettingsScreen(),
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
                          builder: (context) =>
                              const HelpSupportSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Boost Profile Button
            FutureBuilder<bool>(
              future: BoostProfileService().isProfileBoosted(),
              builder: (context, snapshot) {
                final isBoosted = snapshot.data ?? false;

                return AnimatedButton(
                  onPressed: () => _showBoostProfileDialog(),
                  child: GradientButton(
                    onPressed: null, // Handled by AnimatedButton
                    gradient: isBoosted
                        ? LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade600,
                            ],
                          )
                        : null,
                    backgroundColor: isBoosted ? null : const Color(0xFF8B5CF6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isBoosted ? Icons.star : Icons.rocket_launch,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBoosted ? 'Profile Boosted!' : 'Boost Profile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isBoosted) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.timer,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Logout Button with Animation
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: () => _handleLogout(),
                child: GradientButton(
                  onPressed: null, // Handled by AnimatedButton
                  backgroundColor: Colors.red,
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

  Widget _buildPremiumRecommendationCard(User user) {
    final theme = Theme.of(context);

    return ModernCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),

            // Premium features list
            Column(
              children: [
                _buildPremiumFeature(
                  icon: Icons.favorite_rounded,
                  title: 'Unlimited Likes',
                  description: 'Like as many profiles as you want',
                ),
                const SizedBox(height: 8),
                _buildPremiumFeature(
                  icon: Icons.visibility_rounded,
                  title: 'See Who Liked You',
                  description: 'View all your admirers instantly',
                ),
                const SizedBox(height: 8),
                _buildPremiumFeature(
                  icon: Icons.rocket_launch_rounded,
                  title: 'Profile Boosts',
                  description: 'Get more visibility and matches',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: () => _navigateToPremiumUpgrade(),
                child: ElevatedButton(
                  onPressed: null, // Handled by AnimatedButton
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
          ],
        ),
      ),
    );
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
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

  Widget _buildQuickActionsSection(ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildQuickActionItem(
            icon: Icons.search_rounded,
            title: 'Find People',
            subtitle: 'Search and connect with new people',
            iconColor: const Color(0xFFFF2BD3),
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          _buildQuickActionItem(
            icon: Icons.people_rounded,
            title: 'Friend Requests',
            subtitle: 'Manage your friend requests',
            iconColor: const Color(0xFF00E5FF),
            onTap: () => Navigator.pushNamed(context, '/friend-requests'),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          _buildQuickActionItem(
            icon: Icons.favorite_rounded,
            title: 'Friends Section',
            subtitle: 'View and manage your friends',
            iconColor: const Color(0xFF1FE074),
            onTap: () => Navigator.pushNamed(context, '/friends-list'),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
          _buildQuickActionItem(
            icon: Icons.history_rounded,
            title: 'Your Activity',
            subtitle: 'View your recent activity',
            iconColor: theme.colorScheme.primary,
            onTap: () => _showActivityDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
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
}
