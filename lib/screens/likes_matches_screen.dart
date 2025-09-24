import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../services/matching_service.dart';
import '../services/chatify_ad_service.dart';
import '../services/api_service.dart';
import '../services/premium_service.dart';
import '../widgets/user_type_badge.dart';
import '../widgets/chatify_banner_ad.dart';
import '../widgets/blurred_profile_card.dart';
import '../core/theme_extensions.dart';
import '../providers/user_provider.dart';
import '../screens/profile_preview_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/friend_requests_screen.dart';

/// Comprehensive Likes & Matches Screen
/// Shows who liked you, your matches, and liked profiles
class LikesMatchesScreen extends StatefulWidget {
  const LikesMatchesScreen({Key? key}) : super(key: key);

  @override
  State<LikesMatchesScreen> createState() => _LikesMatchesScreenState();
}

class _LikesMatchesScreenState extends State<LikesMatchesScreen>
    with SingleTickerProviderStateMixin {
  final MatchingService _matchingService = MatchingService();
  final ChatifyAdService _adService = ChatifyAdService();
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  // Data states
  List<dynamic> _whoLikedYou = [];
  List<dynamic> _yourMatches = [];
  List<dynamic> _likedProfiles = [];

  // Loading states
  bool _isLoadingWhoLiked = false;
  bool _isLoadingMatches = false;
  bool _isLoadingLiked = false;

  // Error states
  String? _errorWhoLiked;
  String? _errorMatches;
  String? _errorLiked;

  Map<String, dynamic>? _viewInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadWhoLikedYou(),
      _loadYourMatches(),
      _loadLikedProfiles(),
    ]);
  }

  Future<void> _loadWhoLikedYou() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWhoLiked = true;
      _errorWhoLiked = null;
    });

    try {
      // Check if user can view "Who Liked You"
      final canView = await _matchingService.canViewWhoLikedYou();

      if (canView['success'] == false || canView['data']?['canView'] != true) {
        setState(() {
          _errorWhoLiked =
              'Cannot view "Who Liked You" - ${canView['data']?['reason'] ?? 'Permission denied'}';
          _isLoadingWhoLiked = false;
        });
        return;
      }

      _viewInfo = canView['data'] as Map<String, dynamic>?;

      // Get who liked you data
      final result = await _matchingService.getWhoLikedYou(limit: 50);

      if (mounted) {
        setState(() {
          _whoLikedYou =
              List<dynamic>.from(result['whoLikedYou'] as List<dynamic>? ?? []);
          _isLoadingWhoLiked = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage =
            'Failed to load data. Please check your connection and try again.';

        // Check if it's a profile not found error
        if (e.toString().contains('User not found') ||
            e.toString().contains('User not found')) {
          errorMessage =
              'Please create your profile first to view who liked you';
        }

        setState(() {
          _errorWhoLiked = errorMessage;
          _isLoadingWhoLiked = false;
        });
      }
    }
  }

  Future<void> _loadYourMatches() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMatches = true;
      _errorMatches = null;
    });

    try {
      // Get user's matches (mutual likes with active conversations)
      final result = await _apiService.getJson('/matching/matches');

      if (mounted) {
        setState(() {
          _yourMatches =
              List<dynamic>.from(result['matches'] as List<dynamic>? ?? []);
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMatches = 'Failed to load matches. Please try again later.';
          _isLoadingMatches = false;
        });
      }
    }
  }

  Future<void> _loadLikedProfiles() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLiked = true;
      _errorLiked = null;
    });

    try {
      // Get profiles user has liked recently
      final result = await _apiService.getJson('/matching/liked-profiles');

      if (mounted) {
        setState(() {
          _likedProfiles = List<dynamic>.from(
              result['likedProfiles'] as List<dynamic>? ?? []);
          _isLoadingLiked = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLiked =
              'Failed to load liked profiles. Please try again later.';
          _isLoadingLiked = false;
        });
      }
    }
  }

  Future<void> _likeBack(dynamic likedUser) async {
    try {
      final result = await _matchingService.likeUser(
        likedUser['uid'] as String,
        message: "Liked you back!",
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Liked ${(likedUser['displayName'] ?? likedUser['username']) as String} back!'),
            backgroundColor: Colors.green,
          ),
        );

        // Track ad view for connect action
        await _adService.onConnectClick();

        // Remove from list and reload data
        setState(() {
          _whoLikedYou.removeWhere((user) => user['uid'] == likedUser['uid']);
        });

        // Reload matches in case this created a new match
        _loadYourMatches();
      } else {
        final errorMessage = _matchingService.formatMatchingError(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like back: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewUserProfile(dynamic user) async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).currentUser;
      if (currentUser == null) return;

      if (!currentUser.hasFeatureAccess('unlimited_who_liked')) {
        // Show rewarded ad to unlock view
        final success = await _adService.onViewWhoLikedYou();
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Watch an ad to view this profile'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Navigate to profile preview
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ProfilePreviewScreen(
            userId: user['uid'] as String? ?? '',
            initialUserData: user as Map<String, dynamic>?,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to view profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startChat(dynamic match) async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).currentUser;
      if (currentUser == null) return;

      // Check if user has premium access to chat with matches
      final hasAccess = await PremiumService.checkPremiumOrShowPopup(
        context: context,
        feature: 'Chat with Matches',
        description:
            'Start conversations with your matches. Premium users get unlimited access to chat with all their matches.',
      );

      if (!hasAccess) return;

      // Create a Chat object for the navigation
      final chat = Chat(
        id: match['connectionId'] as String,
        name: (match['displayName'] ?? match['username']) as String,
        participantIds: [currentUser.id, match['uid'] as String],
        type: ChatType.friend,
        createdAt: DateTime.parse(match['matchedAt'] as String),
        updatedAt: DateTime.parse(match['matchedAt'] as String),
      );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Remove the app bar height
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite),
              text: 'Liked You (${_whoLikedYou.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Matches (${_yourMatches.length})',
            ),
            Tab(
              icon: const Icon(Icons.person_add),
              text: 'Friend Requests',
            ),
            Tab(
              icon: const Icon(Icons.favorite_border),
              text: 'You Liked (${_likedProfiles.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Add some top spacing to replace the removed app bar
          const SizedBox(height: 16),

          // Banner Ad
          const ChatifyBannerAd(),

          // View Info for "Who Liked You"
          if (_viewInfo != null && _tabController.index == 0) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _viewInfo!['remainingViews'] == -1
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                border: Border.all(
                  color: _viewInfo!['remainingViews'] == -1
                      ? Colors.green.withOpacity(0.5)
                      : Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _viewInfo!['remainingViews'] == -1
                        ? Icons.all_inclusive
                        : Icons.visibility,
                    color: _viewInfo!['remainingViews'] == -1
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _viewInfo!['remainingViews'] == -1
                          ? 'Unlimited views (Premium)'
                          : 'Views remaining: ${_viewInfo!['remainingViews']}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWhoLikedYouTab(theme, tokens),
                _buildMatchesTab(theme, tokens),
                _buildFriendRequestsTab(theme, tokens),
                _buildLikedProfilesTab(theme, tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoLikedYouTab(ThemeData theme, AppThemeTokens tokens) {
    if (_isLoadingWhoLiked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorWhoLiked != null) {
      return _buildErrorState('Error loading who liked you', _errorWhoLiked!,
          _loadWhoLikedYou, theme);
    }

    if (_whoLikedYou.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border,
        'No one has liked you yet',
        'Keep swiping to find matches!',
        theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _whoLikedYou.length,
      itemBuilder: (context, index) {
        final likedUser = _whoLikedYou[index];
        return BlurredProfileListItem(
          profile: likedUser as Map<String, dynamic>,
          onTap: () => _viewUserProfile(likedUser),
        );
      },
    );
  }

  Widget _buildMatchesTab(ThemeData theme, AppThemeTokens tokens) {
    if (_isLoadingMatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMatches != null) {
      return _buildErrorState(
          'Error loading matches', _errorMatches!, _loadYourMatches, theme);
    }

    if (_yourMatches.isEmpty) {
      return _buildEmptyState(
        Icons.people_outline,
        'No matches yet',
        'Start liking profiles to create matches!',
        theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _yourMatches.length,
      itemBuilder: (context, index) {
        final match = _yourMatches[index];
        return BlurredProfileListItem(
          profile: match as Map<String, dynamic>,
          onTap: () => _startChat(match),
        );
      },
    );
  }

  Widget _buildFriendRequestsTab(ThemeData theme, AppThemeTokens tokens) {
    return const FriendRequestsScreen();
  }

  Widget _buildLikedProfilesTab(ThemeData theme, AppThemeTokens tokens) {
    if (_isLoadingLiked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLiked != null) {
      return _buildErrorState('Error loading liked profiles', _errorLiked!,
          _loadLikedProfiles, theme);
    }

    if (_likedProfiles.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border,
        'No liked profiles',
        'Start discovering and liking profiles!',
        theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedProfiles.length,
      itemBuilder: (context, index) {
        final likedProfile = _likedProfiles[index];
        return BlurredProfileListItem(
          profile: likedProfile as Map<String, dynamic>,
          onTap: () => _viewUserProfile(likedProfile),
        );
      },
    );
  }

  Widget _buildUserCard({
    required dynamic user,
    required ThemeData theme,
    required AppThemeTokens tokens,
    required VoidCallback onTap,
    List<Widget>? actions,
    String? subtitle,
    String? message,
    bool isMatch = false,
    bool isLiked = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: isMatch
            ? Colors.green.withOpacity(0.1)
            : Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          side: isMatch
              ? BorderSide(color: Colors.green.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: user['profileImageUrl'] != null
                        ? DecorationImage(
                            image:
                                NetworkImage(user['profileImageUrl'] as String),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user['profileImageUrl'] == null
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (user['displayName'] ?? user['username'])
                                      as String? ??
                                  'Unknown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (user['userTypeBadge'] != null)
                            UserTypeBadge(
                              user: User.fromJson(user as Map<String, dynamic>),
                              size: 16,
                            ),
                          if (isMatch)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'MATCH',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      if (message != null && message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"$message"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  ...actions,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      String title, String message, VoidCallback onRetry, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      IconData icon, String title, String subtitle, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
