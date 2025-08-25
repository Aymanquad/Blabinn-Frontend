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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/general_overlay.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    Colors.black.withOpacity(0.25),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Center(
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
        ],
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/general_overlay.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.transparent,
                    Colors.black.withOpacity(0.22),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
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
            
            const SizedBox(height: 8),
            
            // Credits Display - Use the same source as navbar
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final currentCredits = userProvider.currentUser?.credits ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Credits: $currentCredits',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
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

                         // Boost Profile Button
             FutureBuilder<bool>(
               future: BoostProfileService().isProfileBoosted(),
               builder: (context, snapshot) {
                 final isBoosted = snapshot.data ?? false;
                 
                 return Column(
                   children: [
                     Container(
                       width: double.infinity,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                         gradient: isBoosted 
                           ? LinearGradient(
                               colors: [
                                 Colors.amber.shade400,
                                 Colors.orange.shade600,
                               ],
                             )
                           : null,
                         color: isBoosted ? null : Colors.blue.shade600,
                       ),
                       child: ElevatedButton(
                         onPressed: () => _showBoostProfileDialog(),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.transparent,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                           elevation: 0,
                         ),
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
                     ),
                     

                   ],
                 );
               },
             ),

            const SizedBox(height: 16),

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
        ],
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
                  color: isBoosted ? Colors.amber : Colors.blue,
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Boost Benefits:',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Appear at the top of discover page\n• Get 10x more profile views\n• Stand out with golden shine effect\n• Lasts for 24 hours',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                    backgroundColor: Colors.blue,
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
           print('🔍 DEBUG: ProfileScreen - Updating UserProvider credits to: $newCredits');
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
}
