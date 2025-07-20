import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import 'chat_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
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
      final chat = Chat(
        id: friend['uid'] ?? friend['id'],
        name: friend['displayName'] ?? friend['username'] ?? 'Unknown',
        participantIds: [currentUserId, friend['uid'] ?? friend['id']],
        type: ChatType.friend,
        status: ChatStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

  Future<void> _removeFriend(Map<String, dynamic> friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend['displayName'] ?? friend['username']} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.removeFriend(friend['uid'] ?? friend['id']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadFriends(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final displayName = friend['displayName'] ?? friend['username'] ?? 'Unknown';
    final profilePicture = friend['profilePicture'] as String?;
    final bio = friend['bio'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: profilePicture != null
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
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
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openChatWithFriend(friend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Message'),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
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
                              content: Text('Unable to view profile: User ID not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        break;
                      case 'remove':
                        _removeFriend(friend);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 16),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Remove Friend', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, size: 16),
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
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriends,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFriends,
                        child: const Text('Retry'),
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
                            'No friends yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start connecting with people to build your friends list!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          return _buildFriendCard(_friends[index]);
                        },
                      ),
                    ),
    );
  }
} 