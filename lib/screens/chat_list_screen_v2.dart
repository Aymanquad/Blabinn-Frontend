import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/constants.dart';
import '../widgets/optimized_image.dart';
import '../services/image_preloader.dart';
import '../utils/performance_optimizer.dart';
import '../state/state_selector.dart';

/// Optimized chat list screen with improved image loading
class ChatListScreenV2 extends StatefulWidget {
  const ChatListScreenV2({super.key});

  @override
  State<ChatListScreenV2> createState() => _ChatListScreenV2State();
}

class _ChatListScreenV2State extends State<ChatListScreenV2>
    with PerformanceOptimizedMixin, ImagePreloadingMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  final Map<String, int> _unreadCounts = {};
  final ImagePreloader _preloader = ImagePreloader();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      // Simulate loading friends data
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data for demonstration
      final mockFriends = [
        {
          'id': '1',
          'username': 'john_doe',
          'displayName': 'John Doe',
          'profilePicture': 'https://example.com/profile1.jpg',
          'lastMessage': 'Hey, how are you?',
          'lastMessageTime': '2 min ago',
          'unreadCount': 3,
        },
        {
          'id': '2',
          'username': 'jane_smith',
          'displayName': 'Jane Smith',
          'profilePicture': 'https://example.com/profile2.jpg',
          'lastMessage': 'Thanks for the help!',
          'lastMessageTime': '1 hour ago',
          'unreadCount': 0,
        },
        {
          'id': '3',
          'username': 'mike_wilson',
          'displayName': 'Mike Wilson',
          'profilePicture': 'https://example.com/profile3.jpg',
          'lastMessage': 'See you tomorrow',
          'lastMessageTime': '3 hours ago',
          'unreadCount': 1,
        },
      ];

      setState(() {
        _friends = mockFriends;
        _filteredFriends = List.from(_friends);
      });

      // Preload profile images for better performance
      await preloadUserProfileImages(_friends);
    } catch (e) {
      // Handle error
    }
  }

  void _filterFriends() {
    // Debounce the search to avoid excessive filtering
    debounce('search', () {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        if (query.isEmpty) {
          _filteredFriends = List.from(_friends);
        } else {
          _filteredFriends = _friends.where((friend) {
            final displayName =
                (friend['displayName'] ?? friend['username'] ?? 'Unknown')
                    .toLowerCase();
            final username = (friend['username'] ?? '').toLowerCase();
            return displayName.contains(query) || username.contains(query);
          }).toList();
        }
      });
    }, delay: const Duration(milliseconds: 300));
  }

  void _openChatWithFriend(Map<String, dynamic> friend) {
    // Navigate to chat screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(friend: friend)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_filteredFriends.isEmpty) {
      return _buildEmptyState();
    }

    return PerformanceOptimizer.optimizedListView(
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _filteredFriends[index];
        return _buildChatItem(friend);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to see your chats here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> friend) {
    final theme = Theme.of(context);
    final displayName =
        friend['displayName'] ?? friend['username'] ?? 'Unknown';
    final profilePicture = friend['profilePicture'] as String?;
    final unreadCount = friend['unreadCount'] as int? ?? 0;
    final lastMessage = friend['lastMessage'] as String?;
    final lastMessageTime = friend['lastMessageTime'] as String?;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              child: ListTile(
                leading: Stack(
                  children: [
                    // Optimized profile image with caching
                    OptimizedProfileImage(
                      imageUrl: profilePicture,
                      size: 50,
                      fallbackText: displayName[0].toUpperCase(),
                      enableCache: true,
                    ),
                    // Unread count badge
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
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
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
                          fontWeight: unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    if (lastMessageTime != null)
                      Text(
                        lastMessageTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                onTap: () => _openChatWithFriend(friend),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gallery screen with optimized image loading
class GalleryScreenV2 extends StatefulWidget {
  const GalleryScreenV2({super.key});

  @override
  State<GalleryScreenV2> createState() => _GalleryScreenV2State();
}

class _GalleryScreenV2State extends State<GalleryScreenV2>
    with ImagePreloadingMixin {
  List<String> _imageUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      // Simulate loading images
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock image URLs
      final mockImages = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
        'https://example.com/image3.jpg',
        'https://example.com/image4.jpg',
        'https://example.com/image5.jpg',
        'https://example.com/image6.jpg',
      ];

      setState(() {
        _imageUrls = mockImages;
        _isLoading = false;
      });

      // Preload gallery images
      await preloadImages(_imageUrls, type: ImageType.gallery);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return OptimizedGalleryImage(
            imageUrl: _imageUrls[index],
            onTap: () {
              // Show full screen image
            },
          );
        },
      ),
    );
  }
}

/// Chat screen with optimized image loading
class ChatScreenV2 extends StatefulWidget {
  final Map<String, dynamic> friend;

  const ChatScreenV2({super.key, required this.friend});

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2>
    with ImagePreloadingMixin {
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      // Simulate loading messages
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mock messages with images
      final mockMessages = [
        {
          'id': '1',
          'content': 'Hey, check out this photo!',
          'type': 'text',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'isMe': false,
        },
        {
          'id': '2',
          'content': 'https://example.com/chat_image1.jpg',
          'type': 'image',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
          'isMe': false,
        },
        {
          'id': '3',
          'content': 'That looks amazing!',
          'type': 'text',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          'isMe': true,
        },
      ];

      setState(() {
        _messages = mockMessages;
      });

      // Preload chat images
      final imageUrls = _messages
          .where((msg) => msg['type'] == 'image')
          .map((msg) => msg['content'] as String)
          .toList();
      
      if (imageUrls.isNotEmpty) {
        await preloadImages(imageUrls, type: ImageType.chat);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'type': 'text',
        'timestamp': DateTime.now(),
        'isMe': true,
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            OptimizedProfileImage(
              imageUrl: widget.friend['profilePicture'],
              size: 32,
              fallbackText: widget.friend['displayName'][0].toUpperCase(),
            ),
            const SizedBox(width: 12),
            Text(widget.friend['displayName']),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final type = message['type'] as String;
    final content = message['content'] as String;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: type == 'image'
            ? OptimizedChatImage(
                imageUrl: content,
                width: 200,
                height: 200,
                onTap: () {
                  // Show full screen image
                },
              )
            : Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white,
                ),
              ),
      ),
    );
  }
}
