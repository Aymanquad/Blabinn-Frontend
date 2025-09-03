import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../widgets/consistent_app_bar.dart';


class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _messageNotificationsEnabled = true;
  bool _friendRequestNotificationsEnabled = true;
  bool _randomChatNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _messageNotificationsEnabled = prefs.getBool('message_notifications_enabled') ?? true;
        _friendRequestNotificationsEnabled = prefs.getBool('friend_request_notifications_enabled') ?? true;
        _randomChatNotificationsEnabled = prefs.getBool('random_chat_notifications_enabled') ?? true;
      });
    } catch (e) {
      _showError('Failed to load notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setBool('message_notifications_enabled', _messageNotificationsEnabled);
      await prefs.setBool('friend_request_notifications_enabled', _friendRequestNotificationsEnabled);
      await prefs.setBool('random_chat_notifications_enabled', _randomChatNotificationsEnabled);
      
      // Also save to backend
      await _apiService.updateNotificationSettings({
        'notificationsEnabled': _notificationsEnabled,
        'pushNotificationsEnabled': _pushNotificationsEnabled,
        'soundEnabled': _soundEnabled,
        'vibrationEnabled': _vibrationEnabled,
        'messageNotificationsEnabled': _messageNotificationsEnabled,
        'friendRequestNotificationsEnabled': _friendRequestNotificationsEnabled,
        'randomChatNotificationsEnabled': _randomChatNotificationsEnabled,
      });
      
      _showSuccess('Notification settings updated successfully');
    } catch (e) {
      _showError('Failed to save notification settings: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      // If notifications are disabled, disable all sub-options
      if (!value) {
        _pushNotificationsEnabled = false;
        _soundEnabled = false;
        _vibrationEnabled = false;
        _messageNotificationsEnabled = false;
        _friendRequestNotificationsEnabled = false;
        _randomChatNotificationsEnabled = false;
      }
    });
    await _saveNotificationSettings();
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushNotificationsEnabled = value;
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleSound(bool value) async {
    setState(() {
      _soundEnabled = value;
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleVibration(bool value) async {
    setState(() {
      _vibrationEnabled = value;
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleMessageNotifications(bool value) async {
    setState(() {
      _messageNotificationsEnabled = value;
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleFriendRequestNotifications(bool value) async {
    setState(() {
      _friendRequestNotificationsEnabled = value;
    });
    await _saveNotificationSettings();
  }

  Future<void> _toggleRandomChatNotifications(bool value) async {
    setState(() {
      _randomChatNotificationsEnabled = value;
    });
    await _saveNotificationSettings();
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
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (iconColor ?? AppColors.primary).withOpacity(enabled ? 0.2 : 0.1),
                (iconColor ?? AppColors.primary).withOpacity(enabled ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? (iconColor ?? AppColors.primary) : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: enabled 
                ? Colors.white.withOpacity(0.7)
                : Colors.white.withOpacity(0.5),
          ),
        ),
        trailing: Switch(
          value: value && enabled,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withOpacity(0.3),
        ),
        onTap: enabled ? () => onChanged(!value) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConsistentAppBar(
        title: 'Notification Settings',
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/violettoblack_bg.png'),
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
                    Colors.black.withOpacity(0.18),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          _isLoading
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
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your notification preferences',
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

                  // Master Toggle Section
                  Text(
                    'Master Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingsItem(
                    icon: Icons.notifications_active,
                    title: 'All Notifications',
                    subtitle: _notificationsEnabled
                        ? 'All notifications are enabled'
                        : 'All notifications are disabled',
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    iconColor: _notificationsEnabled ? AppColors.success : AppColors.error,
                  ),

                  const SizedBox(height: 24),

                  // Push Notifications Section
                  Text(
                    'Push Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingsItem(
                    icon: Icons.push_pin,
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications on your device',
                    value: _pushNotificationsEnabled,
                    onChanged: _togglePushNotifications,
                    enabled: _notificationsEnabled,
                  ),

                  const SizedBox(height: 24),

                  // Sound & Vibration Section
                  Text(
                    'Sound & Vibration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingsItem(
                    icon: Icons.volume_up,
                    title: 'Sound',
                    subtitle: 'Play notification sounds',
                    value: _soundEnabled,
                    onChanged: _toggleSound,
                    enabled: _notificationsEnabled,
                  ),

                  _buildSettingsItem(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    subtitle: 'Vibrate on notifications',
                    value: _vibrationEnabled,
                    onChanged: _toggleVibration,
                    enabled: _notificationsEnabled,
                  ),

                  const SizedBox(height: 24),

                  // App Notifications Section
                  Text(
                    'App Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingsItem(
                    icon: Icons.message,
                    title: 'Messages',
                    subtitle: 'Notifications for new messages',
                    value: _messageNotificationsEnabled,
                    onChanged: _toggleMessageNotifications,
                    enabled: _notificationsEnabled,
                  ),

                  _buildSettingsItem(
                    icon: Icons.person_add,
                    title: 'Friend Requests',
                    subtitle: 'Notifications for friend requests',
                    value: _friendRequestNotificationsEnabled,
                    onChanged: _toggleFriendRequestNotifications,
                    enabled: _notificationsEnabled,
                  ),

                  _buildSettingsItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Random Chat',
                    subtitle: 'Notifications for random chat matches',
                    value: _randomChatNotificationsEnabled,
                    onChanged: _toggleRandomChatNotifications,
                    enabled: _notificationsEnabled,
                  ),

                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Some notifications may still appear based on your device settings. '
                          'You can manage these in your device\'s notification settings.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
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
} 