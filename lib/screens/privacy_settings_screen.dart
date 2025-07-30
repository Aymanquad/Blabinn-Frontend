import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart'; // Added import for ThemeProvider
import 'package:provider/provider.dart'; // Added import for Provider

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _locationEnabled = false;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check current location permission status
      final locationStatus = await Permission.location.status;
      setState(() {
        _locationEnabled = locationStatus == PermissionStatus.granted;
      });

      // Load blocked users
      try {
        final blockedUsers = await _apiService.getBlockedUsers();
        setState(() {
          _blockedUsers = List<Map<String, dynamic>>.from(blockedUsers);
        });
      } catch (e) {
        // If loading blocked users fails, set empty list and show warning
        setState(() {
          _blockedUsers = [];
        });
        //print('Warning: Failed to load blocked users: $e');
      }
    } catch (e) {
      _showError('Failed to load privacy settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLocationPermission(bool value) async {
    if (value) {
      // Request location permission
      PermissionStatus status = await Permission.location.status;
      
      if (status == PermissionStatus.denied) {
        status = await Permission.location.request();
      }
      
      if (status == PermissionStatus.granted) {
        setState(() {
          _locationEnabled = true;
        });
        _showSuccess('Location access enabled');
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showLocationPermissionDeniedDialog();
      } else {
        _showLocationPermissionDialog();
      }
    } else {
      // Show dialog to disable location
      _showLocationDisableDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is required for certain features. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it manually in your device settings to use location-based features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Location'),
        content: const Text(
          'Disabling location will limit some features. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _locationEnabled = false;
              });
              _showSuccess('Location access disabled');
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(String userId) async {
    try {
      await _apiService.unblockUser(userId);
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == userId);
      });
      _showSuccess('User unblocked successfully');
    } catch (e) {
      _showError('Failed to unblock user: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.block,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocked Users',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_blockedUsers.length} users blocked',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Blocked users list
          if (_blockedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 48,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No blocked users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Users you block will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: user['profilePicture'] != null
                          ? ClipOval(
                              child: Image.network(
                                user['profilePicture'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, color: AppColors.primary),
                              ),
                            )
                          : Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(
                      user['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Blocked on ${user['blockedAt']?.split('T')[0] ?? 'Unknown date'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _unblockUser(user['id']),
                      child: const Text(
                        'Unblock',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? AppColors.darkPrimary.withOpacity(0.8)
                              : AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.privacy_tip_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Privacy Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Control your privacy and security preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Permission Section
                  Text(
                    'Location Permission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingsItem(
                    icon: Icons.location_on_rounded,
                    title: 'Location Access',
                    subtitle: _locationEnabled
                        ? 'Location access is enabled'
                        : 'Location access is disabled',
                    trailing: Switch(
                      value: _locationEnabled,
                      onChanged: _toggleLocationPermission,
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.3),
                    ),
                    onTap: () => _toggleLocationPermission(!_locationEnabled),
                  ),

                  const SizedBox(height: 24),

                  // Blocked Users Section
                  Text(
                    'Blocked Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildBlockedUsersList(),
                ],
              ),
            ),
    );
  }
} 