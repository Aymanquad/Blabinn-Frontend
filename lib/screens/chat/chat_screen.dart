import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/background_image_service.dart';
import '../../services/chat_moderation_service.dart';
import '../../widgets/chat_bubble.dart';
import 'chat_logic.dart';
import 'chat_ui_components.dart';
import 'chat_image_handler.dart';
import 'chat_user_actions.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final ChatModerationService _moderationService = ChatModerationService();

  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingEarlier = false;
  bool _hasMoreMessages = true;
  String? _earliestMessageId;
  Timer? _typingTimer;
  String? _errorMessage;
  String? _currentUserId;
  String? _friendId;
  bool _isOtherUserTyping = false;

  // Unread message tracking
  int _firstUnreadMessageIndex = -1;
  bool _hasUnreadMessages = false;
  bool _hasScrolledToUnread = false;
  int _unreadCount = 0;
  bool _isMarkingAsRead = false;
  bool _mounted = true;

  // Stream subscriptions for real-time events
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Message>? _messageSentSubscription;
  StreamSubscription<SocketEvent>? _errorSubscription;

  // Initialize chat logic handler
  late ChatLogic _chatLogic;
  late ChatImageHandler _imageHandler;
  late ChatUserActions _userActions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHandlers();
    _initializeAndLoadHistory();
    _setupRealtimeListeners();
    
    // Add scroll listener for marking messages as read
    _scrollController.addListener(_onScroll);
  }

  void _initializeHandlers() {
    _chatLogic = ChatLogic(
      apiService: _apiService,
      socketService: _socketService,
      setState: setState,
      context: context,
      chat: widget.chat,
    );

    _imageHandler = ChatImageHandler(
      apiService: _apiService,
      socketService: _socketService,
      setState: setState,
      context: context,
      friendId: () => _friendId,
    );

    _userActions = ChatUserActions(
      context: context,
      chat: widget.chat,
      friendId: () => _friendId,
    );
  }

  Future<void> _initializeAndLoadHistory() async {
    await _initializeCurrentUser();
    await _loadChatHistory();
    await _connectToRealtimeChat();
    // After loading chat history, check for last image from friend
    _checkAndSaveLastFriendImage();
  }

  Future<void> _initializeCurrentUser() async {
    _currentUserId = await _apiService.getCurrentUserId();
    // print('🔍 DEBUG: Current user ID set to: $_currentUserId');

    // Get friend ID for this chat
    if (widget.chat.isFriendChat) {
      try {
        _friendId =
            widget.chat.participantIds.firstWhere((id) => id != _currentUserId);
      } catch (e) {
        _friendId = widget.chat.id;
      }
    }
    // print('🔍 DEBUG: Friend ID set to: $_friendId');
  }

  Future<void> _connectToRealtimeChat() async {
    // print('🔌 DEBUG: Connecting to socket service...');
    final authService = FirebaseAuthService();
    final user = authService.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        await _socketService.connect(token);

        // Join the appropriate chat room for friend chats
        if (widget.chat.isFriendChat && _friendId != null) {
          // print('🔌 DEBUG: Joining friend chat room with friendId: $_friendId');
          await _socketService.joinChat(_friendId!);

          // Set current chat user to prevent notifications from this friend
          _socketService.setCurrentChatUser(_friendId);
          // print('🔔 DEBUG: Set current chat user to: $_friendId');
        }
      }
    }
  }

  void _setupRealtimeListeners() {
    // Listen for incoming messages
    _messageSubscription = _socketService.messageStream.listen((message) {
      // print('💬 DEBUG: Received real-time message: ${message.content}');

      // Add the message if it's for this chat (either from friend or current user)
      if (widget.chat.isFriendChat &&
          (message.senderId == _friendId || message.receiverId == _friendId)) {
        // Check if this message already exists to avoid duplicates
        bool messageExists = _messages.any((msg) => msg.id == message.id);

        if (!messageExists) {
          // Apply moderation to received message content
          final moderatedMessage = message.copyWith(
            content: _moderationService.moderateReceivedMessage(message.content),
          );

          setState(() {
            _messages.add(moderatedMessage);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            // Update pagination state if we have more than 50 messages
            // This ensures we maintain the "recent 50" concept
            if (_messages.length > 50) {
              // Keep track of the earliest message ID for pagination
              _earliestMessageId = _messages.first.id;
              _hasMoreMessages = true;
            }

          });
          _scrollToBottom();

          // Re-identify unread messages after adding new message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mounted) {
              _identifyUnreadMessages();
            }
          });

          // Note: Image auto-saving is now handled globally by BackgroundImageService
          // through the SocketService, so no need to handle it here specifically
        }
      }
    });

    // Listen for socket events
    _errorSubscription = _socketService.eventStream.listen((event) {
      switch (event) {
        case SocketEvent.message:
          // print('📨 DEBUG: New message event received');
          break;
        case SocketEvent.typing:
          // print('⌨️ DEBUG: Typing event received');
          if (_friendId != null) {
            setState(() {
              _isOtherUserTyping = true;
            });
            // Auto-clear typing indicator after 3 seconds
            Timer(const Duration(seconds: 3), () {
              if (_mounted) {
                setState(() {
                  _isOtherUserTyping = false;
                });
              }
            });
          }
          break;
        case SocketEvent.stopTyping:
          // print('⏹️ DEBUG: Stop typing event received');
          if (_friendId != null) {
            setState(() {
              _isOtherUserTyping = false;
            });
          }
          break;
        case SocketEvent.error:
          // print('🚨 DEBUG: Socket error event');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error occurred'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case SocketEvent.disconnect:
          // print('🔌 DEBUG: Socket disconnected');
          break;
        default:
          break;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Scroll to bottom when dependencies change (widget is fully built)
    if (_messages.isNotEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    
    // Leave the chat room when disposing
    if (widget.chat.isFriendChat && _friendId != null) {
      // print('🔌 DEBUG: Leaving friend chat room with friendId: $_friendId');
      _socketService.leaveChat(_friendId!);

      // Clear current chat user to resume notifications from this friend
      _socketService.clearCurrentChatUser();
      // print('🔔 DEBUG: Cleared current chat user on exit');
    }

    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _typingTimer?.cancel();

    // Cancel real-time subscriptions
    _messageSubscription?.cancel();
    _messageSentSubscription?.cancel();
    _errorSubscription?.cancel();

    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // print('🔍 DEBUG: _loadChatHistory() called');
      Map<String, dynamic> response;

      // Check if this is a friend chat (direct messaging)
      if (widget.chat.isFriendChat) {
        // Use direct friend messaging API
        final currentUserId = await _apiService.getCurrentUserId();
        // print('🔍 DEBUG: Current user ID: $currentUserId');

        if (currentUserId == null) {
          throw Exception('User not logged in');
        }

        String? friendId;
        try {
          friendId = widget.chat.participantIds
              .firstWhere((id) => id != currentUserId);
        } catch (e) {
          friendId = widget.chat.id;
        }

        // print('🔍 DEBUG: Friend ID: $friendId');

        if (friendId == null || friendId.isEmpty) {
          throw Exception('Invalid friend ID');
        }

        // print(
        //     '🔍 DEBUG: Calling getChatHistoryWithUser with friendId: $friendId');
        response = await _apiService.getChatHistoryWithUser(friendId!);
        // print('🔍 DEBUG: Chat history response: $response');

        // Check if there are more messages to load
        final hasMore = response['hasMore'] as bool? ?? false;
        final nextCursor = response['nextCursor'] as String?;

        // print('🔍 DEBUG: Pagination info - hasMore: $hasMore, nextCursor: $nextCursor');

        // Set pagination state BEFORE processing messages
        setState(() {
          _hasMoreMessages = hasMore;
          _earliestMessageId = nextCursor;
        });
      } else {
        // Use room-based messaging (legacy)
        response = await _apiService.getChatMessages(widget.chat.id);
      }

      final messagesData = response['messages'] as List;
      // print('🔍 DEBUG: Found ${messagesData.length} messages in history');

      setState(() {
        try {
          // Sort messages by timestamp (oldest first for chat display)
          // print('🔍 DEBUG: Parsing ${messagesData.length} messages...');
          final messages = <Message>[];

          for (int i = 0; i < messagesData.length; i++) {
            try {
              final message = Message.fromJson(messagesData[i]);
              messages.add(message);
              // print('🔍 DEBUG: Parsed message ${i + 1}: ${message.content}');
            } catch (e) {
              // print('🚨 DEBUG: Error parsing message ${i + 1}: $e');
              // print('🚨 DEBUG: Message data: ${messagesData[i]}');
            }
          }

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _messages = messages;
          _isLoading = false;
          // print('🔍 DEBUG: Successfully parsed ${messages.length} messages');

          // Ensure pagination state is correct after loading messages
          if (_messages.isNotEmpty) {
            // If we have exactly 50 messages and hasMore is true,
            // we know there are more messages to load
            if (_messages.length == 50 && _hasMoreMessages) {
              _earliestMessageId = _messages.first.id;
            }
          }
        } catch (e) {
          // print('🚨 DEBUG: Error in message parsing: $e');
          _isLoading = false;
        }
      });

      // print('🔍 DEBUG: Set ${_messages.length} messages in state');
      // Scroll to appropriate position after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Identify unread messages after current user ID is set
        _identifyUnreadMessages();
        _scrollToAppropriatePosition();
        // Mark messages as read when user opens the chat
        _markMessagesAsReadOnOpen();
      });
      // After loading messages, check for last friend image
      _checkAndSaveLastFriendImage();
    } catch (e) {
      // print('🚨 DEBUG: _loadChatHistory error: $e');
      setState(() {
        _errorMessage = 'Failed to load chat history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _identifyUnreadMessages() {
    if (_currentUserId == null || _messages.isEmpty) return;

    int unreadCount = 0;
    int firstUnreadIndex = -1;

    print('🔍 DEBUG: Identifying unread messages');
    print('🔍 DEBUG: Current user ID: $_currentUserId');
    print('🔍 DEBUG: Friend ID: $_friendId');
    print('🔍 DEBUG: Total messages: ${_messages.length}');

    // Find the first unread message from the friend and count all unread messages
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      // Check if message is from friend and not read (status != "read")
      if (message.senderId == _friendId && 
          message.status != MessageStatus.read) {
        print('🔍 DEBUG: Found unread message at index $i: ${message.content}');
        print('🔍 DEBUG: Message status: ${message.status}');
        if (firstUnreadIndex == -1) {
          firstUnreadIndex = i;
        }
        unreadCount++;
      }
    }

    print('🔍 DEBUG: Total unread count: $unreadCount');
    print('🔍 DEBUG: First unread index: $firstUnreadIndex');

    if (_mounted) {
      setState(() {
        _firstUnreadMessageIndex = firstUnreadIndex;
        _hasUnreadMessages = unreadCount > 0;
        _unreadCount = unreadCount;
      });
    }
  }

  void _scrollToAppropriatePosition() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      if (_hasUnreadMessages && _firstUnreadMessageIndex >= 0 && !_hasScrolledToUnread) {
        // Scroll to the unread messages indicator
        _scrollToUnreadIndicator();
        _hasScrolledToUnread = true;
        
        // Don't automatically scroll to bottom - let user control this
        // User can scroll down or tap to see newer messages
      } else {
        // Scroll to bottom if no unread messages
        _scrollToBottom();
      }
    } else {
      // If scroll controller isn't ready, try again after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToAppropriatePosition();
      });
    }
  }

  void _scrollToUnreadIndicator() {
    if (_firstUnreadMessageIndex < 0 || !_scrollController.hasClients) {
      return;
    }

    print('🔍 DEBUG: _scrollToUnreadIndicator called');
    print('🔍 DEBUG: First unread index: $_firstUnreadMessageIndex');

    // Aggressive approach to ensure it reaches the unread indicator position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      
      // Calculate a more precise offset that shows the unread indicator at the top
      // and the first unread message right below it
      final itemHeight = 150.0; // Increased for very long messages
      final indicatorHeight = 50.0; // Height of the unread indicator
      final padding = 16.0; // Padding to show some context above
      
      // Calculate position to show unread indicator at top with first unread message below
      final offset = (_firstUnreadMessageIndex * itemHeight) - indicatorHeight - padding;
      
      // Ensure we don't scroll beyond the content
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = offset.clamp(0.0, maxScroll);
      
      print('🔍 DEBUG: Calculated offset: $offset');
      print('🔍 DEBUG: Target offset: $targetOffset');
      print('🔍 DEBUG: Max scroll: $maxScroll');
      
      // Force scroll to the unread indicator position immediately
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      // Multiple aggressive attempts to ensure it reaches the unread indicator
      Future.delayed(const Duration(milliseconds: 25), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 75), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _scrollToUnreadMessage() {
    if (_firstUnreadMessageIndex < 0 || !_scrollController.hasClients) {
      return;
    }

    // Aggressive approach to ensure it reaches the unread message position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      
      // Use a larger height estimate for long messages
      final itemHeight = 150.0; // Increased for very long messages
      final offset = (_firstUnreadMessageIndex * itemHeight);
      
      // Ensure we don't scroll beyond the content
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetOffset = offset.clamp(0.0, maxScroll);
      
      // Force scroll to the unread message position immediately
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      // Multiple aggressive attempts to ensure it reaches the unread message
      Future.delayed(const Duration(milliseconds: 25), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 75), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (_friendId == null || _currentUserId == null) return;

    try {
      // Mark all messages from this friend as read
      await _apiService.markAllMessagesAsRead(_friendId!);
      
      // Update local message read status
      if (_mounted) {
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            final message = _messages[i];
            if (message.senderId == _friendId && message.status != MessageStatus.read) {
              _messages[i] = message.copyWith(
                status: MessageStatus.read,
              );
            }
          }
          
          // Re-identify unread messages
          _identifyUnreadMessages();
        });
      }
    } catch (e) {
      // print('🚨 DEBUG: Error marking messages as read: $e');
    }
  }

  void _onScroll() {
    // Mark messages as read when user scrolls to them
    if (_hasUnreadMessages && _scrollController.hasClients) {
      final scrollPosition = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;
      
      // If user has scrolled to the bottom (or near bottom), mark messages as read
      if (scrollPosition >= maxScroll - 100) {
        // Add a small delay to avoid marking as read too quickly
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_hasUnreadMessages && mounted) {
            _markMessagesAsRead();
          }
        });
      }
      
      // Also mark as read if user scrolls past the unread messages
      if (_firstUnreadMessageIndex >= 0) {
        final itemHeight = 80.0; // Approximate height of a message bubble
        final unreadMessagePosition = (_firstUnreadMessageIndex * itemHeight);
        
        if (scrollPosition > unreadMessagePosition + 200) { // 200px past the unread message
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_hasUnreadMessages && mounted) {
              _markMessagesAsRead();
            }
          });
        }
      }
    }
  }

  void _onChatTap() {
    // Mark messages as read when user taps on chat area
    if (_hasUnreadMessages) {
      _markMessagesAsRead();
    }
  }

  // Method to handle when user wants to see newer messages (scroll to bottom)
  void _scrollToNewerMessages() {
    if (_hasUnreadMessages) {
      _markMessagesAsRead();
    }
    _scrollToBottom();
  }

  // Mark messages as read when user opens the chat
  void _markMessagesAsReadOnOpen() {
    // Don't mark as read immediately - let the backend handle it
    // The backend will automatically mark messages as read after 1 second
    // when getChatHistory is called
  }

  Future<void> _loadEarlierMessages() async {
    if (_isLoadingEarlier || !_hasMoreMessages || _earliestMessageId == null) {
      return;
    }

    setState(() {
      _isLoadingEarlier = true;
    });

    try {
      // print('🔍 DEBUG: Loading earlier messages with cursor: $_earliestMessageId');

      final response = await _apiService.getChatHistoryWithUser(
        _friendId!,
        beforeMessageId: _earliestMessageId,
      );

      final messagesData = response['messages'] as List;
      // print('🔍 DEBUG: Loaded ${messagesData.length} earlier messages');

      final earlierMessages = <Message>[];
      for (int i = 0; i < messagesData.length; i++) {
        try {
          final message = Message.fromJson(messagesData[i]);
          earlierMessages.add(message);
        } catch (e) {
          // print('🚨 DEBUG: Error parsing earlier message ${i + 1}: $e');
        }
      }

      // Sort messages by timestamp (oldest first)
      earlierMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        // Insert earlier messages at the beginning
        _messages.insertAll(0, earlierMessages);

        // Update pagination state
        final hasMore = response['hasMore'] as bool? ?? false;
        final nextCursor = response['nextCursor'] as String?;

        // print('🔍 DEBUG: Updated pagination - hasMore: $hasMore, nextCursor: $nextCursor');

        _hasMoreMessages = hasMore;
        _earliestMessageId = nextCursor;
        _isLoadingEarlier = false;

        // Ensure the list is still properly sorted after inserting earlier messages
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      // Re-identify unread messages after loading earlier messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted) {
          _identifyUnreadMessages();
        }
      });

      // print('🔍 DEBUG: Total messages after loading earlier: ${_messages.length}');
    } catch (e) {
      // print('🚨 DEBUG: Error loading earlier messages: $e');
      setState(() {
        _isLoadingEarlier = false;
      });
    }
  }

  void _checkAndSaveLastFriendImage() async {
    if (_messages.isEmpty || _friendId == null) return;
    // Find the last message from the friend
    Message? lastFriendMessage;
    try {
      lastFriendMessage =
          _messages.lastWhere((msg) => msg.senderId == _friendId);
    } catch (e) {
      lastFriendMessage = null;
    }
    if (lastFriendMessage != null &&
        lastFriendMessage.type == MessageType.image &&
        lastFriendMessage.imageUrl != null &&
        lastFriendMessage.imageUrl!.isNotEmpty) {
      // Check if already received
      final alreadyReceived =
          await BackgroundImageService.isImageAlreadyReceived(
        imageUrl: lastFriendMessage.imageUrl!,
        messageId: lastFriendMessage.id,
      );
      if (!alreadyReceived) {
        // Save the image (this will check again inside for race conditions)
        await BackgroundImageService().handleReceivedImageMessage(
            lastFriendMessage,
            senderName: widget.chat.displayName);
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty || _isSending) return;

    if (_friendId == null) {
      // print('❌ DEBUG: Cannot send message - friendId is null');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Process message through moderation service
      final processedMessage = await _moderationService.processMessageForSending(context, messageContent);
      
      if (processedMessage == null) {
        // User cancelled sending due to inappropriate content
        setState(() {
          _isSending = false;
        });
        return;
      }

      // print('📤 DEBUG: Sending message via real-time service');
      // print('📤 DEBUG: Friend ID: $_friendId');
      // print('📤 DEBUG: Message content: $processedMessage');

      // Send processed message via socket service
      await _socketService.sendFriendMessage(_friendId!, processedMessage);

      setState(() {
        _isSending = false;
      });

      _messageController.clear();
      _stopTyping();

      // Mark messages as read when user sends a message
      _markMessagesAsRead();

      // The message will be received via socket and added to the UI automatically
    } catch (e) {
      // print('🚨 DEBUG: Error sending message: $e');
      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMessageChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _startTyping();
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }
    // Trigger rebuild to update the character count and warning icon
    setState(() {});
  }

  void _startTyping() {
    setState(() {
      _isTyping = true;
    });

    // Send typing indicator via real-time service
    if (_friendId != null) {
      // Note: Typing indicator functionality can be added to SocketService if needed
      // print('🔄 DEBUG: Typing indicator - would send to $_friendId');
    }
  }

  void _stopTyping() {
    setState(() {
      _isTyping = false;
    });

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // Stop typing indicator via real-time service
      if (_friendId != null) {
        // Note: Stop typing indicator functionality can be added to SocketService if needed
        // print('🔄 DEBUG: Stop typing indicator - would send to $_friendId');
      }
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    
    // Aggressive approach to ensure it reaches the absolute bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      
      // Force scroll to the absolute bottom immediately
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      // Multiple aggressive attempts to ensure it reaches the bottom
      Future.delayed(const Duration(milliseconds: 25), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 75), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _showExitChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Exit Chat?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit this chat? You can always return to continue the conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitChatDialog();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
        automaticallyImplyLeading: false, // Disable default back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitChatDialog(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                widget.chat.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      // Removed the online status display completely
                      if (_isOtherUserTyping) ...[
                        Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  if (_friendId != null) {
                    Navigator.pushNamed(
                      context,
                      '/user-profile',
                      arguments: _friendId,
                    );
                  }
                  break;
                case 'block':
                  await _userActions.blockUser();
                  break;
                case 'report':
                  // TODO: Report user
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report),
                    SizedBox(width: 8),
                    Text('Report User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_messages.isEmpty
                    ? ChatUIComponents.buildEmptyState(context)
                    : ChatUIComponents.buildMessageList(
                        context,
                        _messages,
                        _currentUserId,
                        _hasMoreMessages,
                        _isLoadingEarlier,
                        _loadEarlierMessages,
                        _scrollController,
                        firstUnreadMessageIndex: _firstUnreadMessageIndex,
                        hasUnreadMessages: _hasUnreadMessages,
                        unreadCount: _unreadCount,
                        onChatTap: _onChatTap,
                        onUnreadIndicatorTap: _scrollToNewerMessages,
                      )),
          ),
          _buildMessageInput(),
        ],
      ),
      ),
    );
  }

  void _showAttachmentOptions() {
    _imageHandler.showAttachmentOptions();
  }

  Widget _buildMessageInput() {
    return ChatUIComponents.buildMessageInput(
      context,
      _messageController,
      _onMessageChanged,
      _sendMessage,
      _showAttachmentOptions,
    );
  }
}
