import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _chatRooms = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatsData();
  }

  Future<void> _loadChatsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load friends and chat rooms in parallel
      final results = await Future.wait([
        _apiService.getFriends(),
        _apiService.getFriendChatRooms(),
        _apiService.getUnreadMessageCount(),
      ]);

      if (mounted) {
        setState(() {
          _friends = results[0] as List<Map<String, dynamic>>;
          _chatRooms = results[1] as List<Map<String, dynamic>>;
          final unreadResponse = results[2] as Map<String, dynamic>;
          _unreadCounts = Map<String, int>.from(unreadResponse['unreadCounts'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load chats: ${e.toString()}';
          _isLoading = false;
        });
      }
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
        unreadCount: _unreadCounts[friend['uid'] ?? friend['id']] ?? 0,
      );

      // Navigate to chat screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );

      // Refresh chat list when returning from chat
      if (result == true) {
        _loadChatsData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildChatItem(Map<String, dynamic> friend) {
    final displayName = friend['displayName'] ?? friend['username'] ?? 'Unknown';
    final profilePicture = friend['profilePicture'] as String?;
    final unreadCount = _unreadCounts[friend['uid'] ?? friend['id']] ?? 0;
    final lastMessage = friend['lastMessage'] as String?;
    final lastMessageTime = friend['lastMessageTime'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: profilePicture != null
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage != null)
              Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            if (lastMessageTime != null)
              Text(
                lastMessageTime,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NEW',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _openChatWithFriend(friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatsData,
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
                        onPressed: _loadChatsData,
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
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No friends to chat with yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add friends to start chatting!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChatsData,
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          return _buildChatItem(_friends[index]);
                        },
                      ),
                    ),
    );
  }
} 