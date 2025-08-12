import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../widgets/banner_ad_widget.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  List<Map<String, dynamic>> _chatRooms = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatsData();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_friends);
      } else {
        _filteredFriends = _friends.where((friend) {
          final displayName = (friend['displayName'] ?? friend['username'] ?? 'Unknown').toLowerCase();
          final username = (friend['username'] ?? '').toLowerCase();
          return displayName.contains(query) || username.contains(query);
        }).toList();
      }
    });
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
          _filteredFriends = List.from(_friends);
          _chatRooms = results[1] as List<Map<String, dynamic>>;
          final unreadResponse = results[2] as Map<String, dynamic>;
          _unreadCounts =
              Map<String, int>.from(unreadResponse['unreadBySender'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Provide a more user-friendly error message
          if (e.toString().contains('unread message count')) {
            _errorMessage =
                'Unable to load unread message counts. Your chats will still work normally.';
          } else {
            _errorMessage = 'Failed to load chats: ${e.toString()}';
          }
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
    final theme = Theme.of(context);
    final displayName =
        friend['displayName'] ?? friend['username'] ?? 'Unknown';
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
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage:
                  profilePicture != null ? NetworkImage(profilePicture) : null,
              child: profilePicture == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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
                  decoration: BoxDecoration(
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            if (lastMessageTime != null)
              Text(
                lastMessageTime,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
            : Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
        onTap: () => _openChatWithFriend(friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/violettoblack_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // The filtering is handled by the listener
                  },
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurface.withOpacity(0.7),
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
                            );
                          },
                        )
                      : _filteredFriends.isEmpty
                          ? Builder(
                              builder: (context) {
                                final theme = Theme.of(context);
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _searchController.text.isNotEmpty
                                            ? Icons.search_off
                                            : Icons.chat_bubble_outline,
                                        size: 64,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isNotEmpty
                                            ? 'No friends found'
                                            : 'No friends to chat with yet',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchController.text.isNotEmpty
                                            ? 'Try a different search term'
                                            : 'Add friends to start chatting!',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : RefreshIndicator(
                              onRefresh: _loadChatsData,
                              child: ListView.builder(
                                itemCount: _filteredFriends.length,
                                itemBuilder: (context, index) {
                                  return _buildChatItem(_filteredFriends[index]);
                                },
                              ),
                            ),
            ),
            // Banner Ad at the bottom
            const BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(bottom: 8),
            ),
          ],
        ),
      ),
    );
  }
}
