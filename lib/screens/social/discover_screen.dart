import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/matching_service.dart';
import '../../services/chatify_ad_service.dart';
import '../../widgets/user_type_badge.dart';
import '../../widgets/chatify_banner_ad.dart';
import '../../widgets/premium_feature_widget.dart';
import '../../core/theme_extensions.dart';
import '../../providers/user_provider.dart';

/// Discover Screen
/// Shows potential matches with user type restrictions and ad integration
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final MatchingService _matchingService = MatchingService();
  final ChatifyAdService _adService = ChatifyAdService();

  List<User> _potentialMatches = [];
  bool _isLoading = false;
  String? _error;
  int _currentIndex = 0;

  // Filters
  String? _selectedGender;
  int? _minAge;
  int? _maxAge;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPotentialMatches() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _matchingService.getPotentialMatches(
        gender: _selectedGender,
        minAge: _minAge,
        maxAge: _maxAge,
        location: _selectedLocation,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _potentialMatches = matches;
          _currentIndex = 0;
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

  Future<void> _likeUser(User user) async {
    try {
      final result = await _matchingService.likeUser(user.uid,
          message: "I liked your profile!");

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liked ${user.displayName ?? user.username}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Track ad view for connect action
        await _adService.onConnectClick();

        // Move to next user
        _nextUser();
      } else {
        // Show error message
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
          content: Text('Failed to like user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _superLikeUser(User user) async {
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    // Check if user can use super likes
    if (!_matchingService.canUseSuperLike(currentUser)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Super likes not available for your user type or limit reached'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await _matchingService.superLikeUser(user.uid,
          message: "Super like! ⭐");

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Super liked ${user.displayName ?? user.username}! ⭐'),
            backgroundColor: Colors.purple,
          ),
        );

        // Track ad view for connect action
        await _adService.onConnectClick();

        // Move to next user
        _nextUser();
      } else {
        // Show error message
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
          content: Text('Failed to super like user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextUser() {
    if (_currentIndex < _potentialMatches.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Load more matches
      _loadPotentialMatches();
    }
  }

  void _previousUser() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _startInstantMatch() async {
    try {
      final result = await _matchingService.startInstantMatch();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instant match started!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to chat or show match result
        // You can implement navigation to chat screen here
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to start instant match: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start instant match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final currentUser = userProvider.currentUser;
              final hasInstantMatch = currentUser != null &&
                  currentUser.hasFeatureAccess('instant_match');

              return PremiumFeatureWidget(
                feature: 'instant_match',
                onTap: hasInstantMatch ? _startInstantMatch : null,
                showUpgradeButton: false,
                child: IconButton(
                  onPressed: hasInstantMatch ? _startInstantMatch : null,
                  icon: const Icon(Icons.flash_on),
                  tooltip: 'Instant Match',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPotentialMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad
          const ChatifyBannerAd(),

          // User Type Info
          if (currentUser != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(tokens.radiusM),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  UserTypeBadge(user: currentUser, compact: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _matchingService
                          .getUserTypeExplanation(currentUser.userType),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
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
              'Error loading matches',
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
              onPressed: _loadPotentialMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_potentialMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPotentialMatches,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    if (_currentIndex >= _potentialMatches.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve seen all matches!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new matches',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPotentialMatches,
              child: const Text('Load More'),
            ),
          ],
        ),
      );
    }

    final currentUser = _potentialMatches[_currentIndex];
    return _buildUserCard(currentUser, theme, tokens);
  }

  Widget _buildUserCard(User user, ThemeData theme, AppThemeTokens tokens) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tokens.radiusL),
                ),
                image: user.profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.profileImageUrl == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(tokens.radiusL),
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    )
                  : null,
            ),

            // User Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? user.username,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      UserTypeBadge(user: user, compact: true),
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (user.age != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.cake,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.age} years old',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (user.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.location!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Button
                  IconButton(
                    onPressed: _currentIndex > 0 ? _previousUser : null,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Super Like Button
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final currentUser = userProvider.currentUser;
                      final canSuperLike = currentUser != null &&
                          _matchingService.canUseSuperLike(currentUser);

                      return PremiumFeatureWidget(
                        feature: 'super_likes',
                        onTap: canSuperLike ? () => _superLikeUser(user) : null,
                        showUpgradeButton: false,
                        child: IconButton(
                          onPressed:
                              canSuperLike ? () => _superLikeUser(user) : null,
                          icon: const Icon(Icons.star),
                          style: IconButton.styleFrom(
                            backgroundColor: canSuperLike
                                ? Colors.purple.withOpacity(0.8)
                                : Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  // Like Button
                  IconButton(
                    onPressed: () => _likeUser(user),
                    icon: const Icon(Icons.favorite),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Next Button
                  IconButton(
                    onPressed: _currentIndex < _potentialMatches.length - 1
                        ? _nextUser
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Min Age'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _minAge = int.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Max Age'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxAge = int.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedGender = null;
                _minAge = null;
                _maxAge = null;
                _selectedLocation = null;
              });
              Navigator.pop(context);
              _loadPotentialMatches();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadPotentialMatches();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
