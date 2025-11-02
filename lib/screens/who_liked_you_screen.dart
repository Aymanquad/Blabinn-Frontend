import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/matching_service.dart';
import '../services/chatify_ad_service.dart';
import '../widgets/user_type_badge.dart';
import '../widgets/chatify_banner_ad.dart';
import '../core/theme_extensions.dart';
import '../providers/user_provider.dart';

/// Who Liked You Screen
/// Shows users who liked the current user with ad integration and view limits
class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({Key? key}) : super(key: key);

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  final MatchingService _matchingService = MatchingService();
  final ChatifyAdService _adService = ChatifyAdService();
  
  List<dynamic> _whoLikedYou = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _viewInfo;

  @override
  void initState() {
    super.initState();
    _loadWhoLikedYou();
  }

  Future<void> _loadWhoLikedYou() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check if user can view "Who Liked You"
      final canView = await _matchingService.canViewWhoLikedYou();
      
      if (!canView['canView']) {
        setState(() {
          _error = 'Cannot view "Who Liked You" - ${canView['reason']}';
          _isLoading = false;
        });
        return;
      }

      _viewInfo = canView;

      // Get who liked you data
      final result = await _matchingService.getWhoLikedYou(limit: 20);
      
      if (mounted) {
        setState(() {
          _whoLikedYou = List<dynamic>.from(result['whoLikedYou'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewUserProfile(dynamic likedUser) async {
    try {
      // Check if user can view profiles (premium feature or ad)
      final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
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

      // Navigate to profile or show profile details
      _showUserProfileDialog(likedUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to view profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserProfileDialog(dynamic likedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(likedUser['displayName'] ?? likedUser['username']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (likedUser['profileImageUrl'] != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(likedUser['profileImageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (likedUser['bio'] != null && likedUser['bio'].isNotEmpty)
              Text(likedUser['bio']),
            if (likedUser['age'] != null) ...[
              const SizedBox(height: 8),
              Text('Age: ${likedUser['age']}'),
            ],
            if (likedUser['location'] != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${likedUser['location']}'),
            ],
            const SizedBox(height: 8),
            Text('Liked you on: ${_formatDate(likedUser['requestDate'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _likeBack(likedUser);
            },
            child: const Text('Like Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _likeBack(dynamic likedUser) async {
    try {
      final result = await _matchingService.likeUser(
        likedUser['uid'],
        message: "Liked you back!",
      );
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liked ${likedUser['displayName'] ?? likedUser['username']} back!'),
            backgroundColor: Colors.green,
          ),
        );

        // Track ad view for connect action
        await _adService.onConnectClick();
        
        // Remove from list
        setState(() {
          _whoLikedYou.removeWhere((user) => user['uid'] == likedUser['uid']);
        });
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
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Liked You'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWhoLikedYou,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad
          const ChatifyBannerAd(),
          
          // View Info
          if (_viewInfo != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _viewInfo!['remainingViews'] == -1 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(tokens.radiusM),
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
                        ? Icons.unlimited
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

          // Main Content
          Expanded(
            child: _buildMainContent(theme, tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, AppThemeTokens tokens) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              'Error loading who liked you',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWhoLikedYou,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_whoLikedYou.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No one has liked you yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep swiping to find matches!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go to Discover'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _whoLikedYou.length,
      itemBuilder: (context, index) {
        final likedUser = _whoLikedYou[index];
        return _buildLikedUserCard(likedUser, theme, tokens);
      },
    );
  }

  Widget _buildLikedUserCard(dynamic likedUser, ThemeData theme, AppThemeTokens tokens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusM),
        ),
        child: InkWell(
          onTap: () => _viewUserProfile(likedUser),
          borderRadius: BorderRadius.circular(tokens.radiusM),
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
                    image: likedUser['profileImageUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(likedUser['profileImageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: likedUser['profileImageUrl'] == null
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
                              likedUser['displayName'] ?? likedUser['username'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (likedUser['userTypeBadge'] != null)
                            UserTypeBadge(
                              user: User.fromJson(likedUser),
                              compact: true,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'Liked you ${_formatDate(likedUser['requestDate'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      if (likedUser['requestMessage'] != null && 
                          likedUser['requestMessage'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${likedUser['requestMessage']}"',
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

                // Like Back Button
                IconButton(
                  onPressed: () => _likeBack(likedUser),
                  icon: const Icon(Icons.favorite),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
