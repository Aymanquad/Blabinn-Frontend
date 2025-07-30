import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../screens/chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friends = await _apiService.getFriends();
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load friends: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _openChatWithFriend(Map<String, dynamic> friend) async {
    try {
      final currentUserId = await _apiService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Create a chat object for the friend
      final chat = Chat.friend(
        id: friend['uid'] ?? friend['id'],
        name: friend['displayName'] ?? friend['username'] ?? 'Unknown',
        participantIds: [currentUserId, friend['uid'] ?? friend['id']],
      );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFriend(String friendUserId) async {
    try {
      await _apiService.removeFriend(friendUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadFriends(); // Reload to update the list
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

  void _showRemoveFriendDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${friend['displayName'] ?? friend['username']} from your friends?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFriend(friend['uid']);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
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
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: friend['profilePicture'] != null
                  ? NetworkImage(friend['profilePicture'])
                  : null,
              child: friend['profilePicture'] == null
                  ? Text(
                      (friend['displayName'] ?? friend['username'] ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['displayName'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${friend['username'] ?? 'unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (friend['bio'] != null && friend['bio'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        friend['bio'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'chat':
                    _openChatWithFriend(friend);
                    break;
                  case 'profile':
                    final userId = friend['uid'] ?? friend['id'];
                    if (userId != null) {
                      Navigator.pushNamed(
                        context,
                        '/user-profile',
                        arguments: userId,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Unable to view profile: User ID not found'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    break;
                  case 'remove':
                    _showRemoveFriendDialog(friend);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 20),
                      SizedBox(width: 8),
                      Text('Send Message'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Friend',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriends,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
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
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
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
                        onPressed: _loadFriends,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _friends.isEmpty
                  ? Center(
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
                            'No Friends Yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start connecting with people to see them here!',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/search');
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Find People'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          return _buildFriendCard(_friends[index]);
                        },
                      ),
                    ),
    );
  }
}
