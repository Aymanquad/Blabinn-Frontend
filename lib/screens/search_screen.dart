import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID to filter out from results
      final currentUserId = await _apiService.getCurrentUserId(); 
      
      final results = await _apiService.searchProfiles({
        'searchTerm': _searchController.text.trim(),
        'limit': 20,
      });

      //print('🔍 DEBUG: Search results received: ${results.length} users');
      //print('🔍 DEBUG: Current user ID: $currentUserId');
      
      // Filter out current user from results
      final filteredResults = results.where((user) {
        final userId = user['uid'] ?? user['id'];
        return userId != currentUserId;
      }).toList();

      //print('🔍 DEBUG: Filtered results: ${filteredResults.length} users (removed current user)');
      
      // Check connection status for each user
      final resultsWithStatus = <Map<String, dynamic>>[];
      for (final user in filteredResults) {
        final userId = user['uid'] ?? user['id'];
        try {
          final connectionStatus = await _apiService.getConnectionStatus(userId);
          user['connectionStatus'] = connectionStatus['status'] ?? 'none';
          user['connectionType'] = connectionStatus['type'] ?? 'none';
          //print('🔍 DEBUG: User ${user['username']} - Connection status: ${user['connectionStatus']}');
        } catch (e) {
          // If connection status check fails, assume no connection
          user['connectionStatus'] = 'none';
          user['connectionType'] = 'none';
          //print('🔍 DEBUG: Failed to get connection status for ${user['username']}: $e');
        }
        resultsWithStatus.add(user);
      }

      setState(() {
        _searchResults = resultsWithStatus;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      //print('❌ ERROR: Search failed: $e');
      setState(() {
        _errorMessage = 'Failed to search: ${e.toString()}';
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    try {
      //print('🔍 DEBUG: Sending friend request to user: $targetUserId');

      if (targetUserId.isEmpty) {
        throw Exception('Invalid user ID: User ID cannot be empty');
      }

      await _apiService.sendFriendRequest(targetUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      //print('❌ ERROR: Failed to send friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for people...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _performSearch(),
        onChanged: (value) {
          if (value.isEmpty) {
            _performSearch();
          }
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return SkeletonList(
        itemCount: 6,
        itemBuilder: (context, index) => SkeletonLayouts.searchResult(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for People',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a name, username, or interest to find people',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user['profilePicture'] != null
                  ? NetworkImage(user['profilePicture'])
                  : null,
              child: user['profilePicture'] == null
                  ? Text(
                      (user['displayName'] ?? user['username'] ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                  Text(
                    user['displayName'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user['username'] ?? 'unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (user['bio'] != null && user['bio'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user['bio'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (user['interests'] != null &&
                      user['interests'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (user['interests'] as List<dynamic>)
                          .take(3)
                          .map((interest) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  interest.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action Button
            _buildActionButton(user),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> user) {
    final connectionStatus = user['connectionStatus'] ?? 'none';
    final isAlreadyFriend = connectionStatus == 'accepted' || connectionStatus == 'friends';
    final isPending = connectionStatus == 'pending';
    
    String buttonText;
    Color buttonColor;
    Color textColor;
    bool isEnabled;
    
    if (isAlreadyFriend) {
      buttonText = 'Already Friends';
      buttonColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
      isEnabled = false;
    } else if (isPending) {
      buttonText = 'Request Sent';
      buttonColor = Colors.orange[100]!;
      textColor = Colors.orange[700]!;
      isEnabled = false;
    } else {
      buttonText = 'Connect';
      buttonColor = AppColors.primary;
      textColor = Colors.white;
      isEnabled = true;
    }

    return ElevatedButton(
      onPressed: isEnabled ? () {
        final userId = user['uid'] ?? user['id'];
        if (userId != null) {
          _sendFriendRequest(userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect: User ID not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: isEnabled ? 2 : 0,
      ),
      child: Text(buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search People',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body:
          Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          ),
    );
  }
}
