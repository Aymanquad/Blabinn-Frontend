import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/full_screen_image_viewer.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialUserData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUserData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  List<String> _galleryImages = [];
  bool _isLoading = false;
  bool _isGalleryLoading = false;
  String? _errorMessage;
  String? _connectionStatus;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserGallery();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If we have initial data, use it
      if (widget.initialUserData != null) {
        _userData = widget.initialUserData;
        _isLoading = false;
      } else {
        // Otherwise fetch from API
        final userData = await _apiService.getUserProfile(widget.userId);
        print('DEBUG: Received user data: $userData'); // Debug log
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }

      // Check if this is current user
      final currentUserId = await _apiService.getCurrentUserId();
      _isCurrentUser = currentUserId == widget.userId;

      // Get connection status
      if (!_isCurrentUser) {
        await _loadConnectionStatus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserGallery() async {
    setState(() {
      _isGalleryLoading = true;
    });

    try {
      // For now, we'll try to load gallery from the profile data
      // This could be extended to load from a separate gallery endpoint
      if (_userData?['gallery'] != null) {
        _galleryImages = List<String>.from(_userData!['gallery']);
      }
    } catch (e) {
      print('Failed to load user gallery: $e');
      // Don't show error for gallery, it's optional
    } finally {
      setState(() {
        _isGalleryLoading = false;
      });
    }
  }

  Future<void> _loadConnectionStatus() async {
    try {
      final statusData = await _apiService.getConnectionStatus(widget.userId);
      setState(() {
        _connectionStatus = statusData['status'];
      });
    } catch (e) {
      // Connection status is optional, don't show error
      print('Failed to load connection status: $e');
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _apiService.sendFriendRequest(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadConnectionStatus(); // Refresh status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFriend() async {
    try {
      await _apiService.removeFriend(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadConnectionStatus(); // Refresh status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButton(bool isDarkMode) {
    if (_isCurrentUser) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/profile-management');
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      );
    }

    switch (_connectionStatus) {
      case 'none':
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(Icons.person_add),
          label: const Text('Send Friend Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        );
      case 'pending_sent':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule),
          label: const Text('Request Sent'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
            side: BorderSide(color: isDarkMode ? AppColors.darkPrimary : AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        );
      case 'pending_received':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Accept friend request
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accept request feature coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Reject friend request
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reject request feature coming soon!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        );
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat feature coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppColors.darkSecondary : AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _removeFriend,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Icon(Icons.person_remove),
            ),
          ],
        );
      default:
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(Icons.person_add),
          label: const Text('Send Friend Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        );
    }
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDarkMode ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.1),
            (isDarkMode ? AppColors.darkSecondary : AppColors.secondary).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDarkMode ? AppColors.darkText : AppColors.text).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDarkMode ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: (isDarkMode ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.1),
                  backgroundImage: _userData?['profilePicture'] != null
                      ? NetworkImage(_userData!['profilePicture'])
                      : null,
                  child: _userData?['profilePicture'] == null
                      ? Text(
                          (_userData?['displayName'] ?? _userData?['username'] ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              if (_connectionStatus == 'accepted')
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userData?['displayName'] ?? 'Unknown User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${_userData?['username'] ?? 'unknown'}',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildActionButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildBioSection(bool isDarkMode) {
    final theme = Theme.of(context);
    final bio = _userData?['bio'];
    
    if (bio == null || bio.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio.toString(),
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(bool isDarkMode) {
    final theme = Theme.of(context);
    final interests = _userData?['interests'];
    
    if (interests == null || (interests is List && interests.isEmpty)) {
      return const SizedBox.shrink();
    }

    final interestsList = interests is List ? interests.cast<String>() : <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: isDarkMode ? AppColors.darkAccent : AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Interests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interestsList.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDarkMode ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(bool isDarkMode) {
    final theme = Theme.of(context);
    
    // For demo, we'll create some sample gallery images from profile picture
    List<String> galleryImages = [];
    if (_userData?['profilePicture'] != null) {
      galleryImages = [_userData!['profilePicture']];
    }
    
    // Add any additional gallery images from userData
    if (_userData?['gallery'] != null && _userData!['gallery'] is List) {
      galleryImages.addAll(List<String>.from(_userData!['gallery']));
    }

    if (galleryImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: isDarkMode ? AppColors.darkSecondary : AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${galleryImages.length} ${galleryImages.length == 1 ? 'photo' : 'photos'}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imageUrl: galleryImages[index],
                        heroTag: 'gallery_$index',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'gallery_$index',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        galleryImages[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: theme.colorScheme.surface,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surface,
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          );
                        },
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

  Widget _buildProfileDetails(bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: _userData?['email'] ?? 'Not provided',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: _userData?['location'] ?? 'Not provided',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.calendar_today_outlined,
            title: 'Joined',
            value: _getCreatedAtYear(),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCreatedAtYear() {
    try {
      final createdAt = _userData?['createdAt'];
      if (createdAt == null) return 'Unknown';

      // Handle different date formats
      if (createdAt is String) {
        return DateTime.parse(createdAt).year.toString();
      } else if (createdAt is Map) {
        // Handle Firestore timestamp format
        final seconds = createdAt['_seconds'] as int?;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
              .year
              .toString();
        }
      }
      return 'Unknown';
    } catch (e) {
      print('DEBUG: Error parsing createdAt: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text('Profile'),
            elevation: 0,
            actions: [
              if (!_isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: theme.colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _buildBottomSheet(isDarkMode),
                    );
                  },
                ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(isDarkMode),
                          const SizedBox(height: 20),
                          _buildBioSection(isDarkMode),
                          const SizedBox(height: 20),
                          _buildInterestsSection(isDarkMode),
                          const SizedBox(height: 20),
                          _buildGallerySection(isDarkMode),
                          const SizedBox(height: 20),
                          _buildProfileDetails(isDarkMode),
                          const SizedBox(height: 20), // Bottom padding
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildBottomSheet(bool isDarkMode) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              Icons.chat,
              color: isDarkMode ? AppColors.darkSecondary : AppColors.secondary,
            ),
            title: const Text('Send Message'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to chat with this user
              // You'll need to implement proper chat navigation
              // For now, show a placeholder message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening chat with ${_userData?['displayName'] ?? 'user'}...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.block,
              color: Colors.red,
            ),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Block user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Block feature coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.report,
              color: Colors.orange,
            ),
            title: const Text('Report User'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Report user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
