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
  bool _showScrollToBottomButton = false;
  bool _isKeyboardVisible = false;

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
    _setupScrollListener();
    _setupKeyboardListener();
  }

  void _setupKeyboardListener() {
    // Listen for keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaQuery = MediaQuery.of(context);
      final keyboardHeight = mediaQuery.viewInsets.bottom;
      final isKeyboardVisible = keyboardHeight > 0;

      if (isKeyboardVisible != _isKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = isKeyboardVisible;
        });

        // If keyboard just appeared and we have messages, scroll to bottom
        if (isKeyboardVisible && _messages.isNotEmpty) {
          // Multiple attempts to ensure scrolling works when keyboard appears
          Future.delayed(const Duration(milliseconds: 10), () {
            if (mounted) {
              _scrollToBottom();
            }
          });

          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _scrollToBottom();
            }
          });

          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _scrollToBottom();
            }
          });
        }
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // This is called when the keyboard appears/disappears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mediaQuery = MediaQuery.of(context);
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final isKeyboardVisible = keyboardHeight > 0;

        if (isKeyboardVisible != _isKeyboardVisible) {
          setState(() {
            _isKeyboardVisible = isKeyboardVisible;
          });

          // If keyboard just appeared and we have messages, scroll to bottom
          if (isKeyboardVisible && _messages.isNotEmpty) {
            // Multiple attempts to ensure scrolling works when keyboard appears
            Future.delayed(const Duration(milliseconds: 10), () {
              if (mounted) {
                _scrollToBottom();
              }
            });

            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _scrollToBottom();
              }
            });

            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _scrollToBottom();
              }
            });
          }
        }
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        final isAtBottom = currentScroll >= maxScroll - 100; // 100px threshold

        setState(() {
          // Only show scroll button if not at bottom and keyboard is not visible
          // When keyboard is visible, we want to always show the scroll button if not at bottom
          _showScrollToBottomButton = !isAtBottom && _messages.isNotEmpty;
        });
      }
    });
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
            content:
                _moderationService.moderateReceivedMessage(message.content),
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

          // Always scroll to bottom for new messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Update scroll button state
          setState(() {
            _showScrollToBottomButton =
                false; // Hide button since we're at bottom
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
    _scrollController.dispose();
    _typingTimer?.cancel();

    // Cancel real-time subscriptions
    _messageSubscription?.cancel();
    _messageSentSubscription?.cancel();
    _errorSubscription?.cancel();

    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    if (_isLoading) return;

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

        // Store friendId for later use
        _friendId = friendId;

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

      // Ensure we scroll to the bottom after loading messages
      // Use multiple post-frame callbacks to ensure scrolling works
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Additional scroll attempt with delay to ensure it works
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToBottom();
        }
      });

      // After loading messages, check for last friend image
      _checkAndSaveLastFriendImage();

      // Check if we need to load more recent messages
      await _ensureLatestMessages();
    } catch (e) {
      // print('🚨 DEBUG: _loadChatHistory error: $e');
      setState(() {
        _errorMessage = 'Failed to load chat history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Ensure we have the latest messages by checking if there are newer messages
  Future<void> _ensureLatestMessages() async {
    if (_friendId == null || _messages.isEmpty) return;

    try {
      // Get the latest message to compare with our current messages
      final latestMessageData =
          await _apiService.getLatestMessageWithUser(_friendId!);
      if (latestMessageData != null && latestMessageData['message'] != null) {
        final latestMessage = Message.fromJson(latestMessageData['message']);

        // Check if we already have this message
        final hasLatestMessage =
            _messages.any((msg) => msg.id == latestMessage.id);

        if (!hasLatestMessage) {
          // We don't have the latest message, so we need to reload
          // print('🔍 DEBUG: Latest message not found in current messages, reloading...');
          await _loadChatHistory();
        }
      }
    } catch (e) {
      // print('🚨 DEBUG: Error ensuring latest messages: $e');
      // Don't throw here, just log the error
    }
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
      final processedMessage = await _moderationService
          .processMessageForSending(context, messageContent);

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

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Update scroll button state
      setState(() {
        _showScrollToBottomButton = false; // Hide button since we're at bottom
      });

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
      // Scroll to bottom when user starts typing to ensure latest messages are visible
      if (_messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 10), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
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

    // Scroll to bottom when user starts typing to ensure latest messages are visible
    if (_messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }

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
    if (!mounted || _messages.isEmpty) return;

    // Immediate scroll attempt for instant response
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    // Use multiple attempts to ensure scrolling works
    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController
            .animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150), // Faster animation
          curve: Curves.easeOut,
        )
            .then((_) {
          // Hide scroll button after scrolling to bottom
          if (mounted) {
            setState(() {
              _showScrollToBottomButton = false;
            });
          }
        });
      }
    });

    // Second attempt with longer delay in case first one fails
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController
            .animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150), // Faster animation
          curve: Curves.easeOut,
        )
            .then((_) {
          // Hide scroll button after scrolling to bottom
          if (mounted) {
            setState(() {
              _showScrollToBottomButton = false;
            });
          }
        });
      }
    });

    // Third attempt with even longer delay for edge cases
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController
            .animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150), // Faster animation
          curve: Curves.easeOut,
        )
            .then((_) {
          // Hide scroll button after scrolling to bottom
          if (mounted) {
            setState(() {
              _showScrollToBottomButton = false;
            });
          }
        });
      }
    });
  }

  void _showExitChatDialog() {
    // For friend chats, don't show confirmation dialog
    if (widget.chat.isFriendChat) {
      Navigator.pop(context); // Exit chat directly
      return;
    }

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
        // For friend chats, allow direct back navigation
        if (widget.chat.isFriendChat) {
          return true; // Allow default back button behavior
        }
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
                        if (_isTyping) ...[
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
                        )),
            ),
            _buildMessageInput(),
          ],
        ),
        floatingActionButton: _showScrollToBottomButton
            ? FloatingActionButton(
                onPressed: _scrollToBottom,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.keyboard_arrow_down),
              )
            : null,
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
      onTextFieldTap: () {
        // Scroll to bottom when user taps on text field
        if (_messages.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 10), () {
            if (mounted) {
              _scrollToBottom();
            }
          });
        }
      },
    );
  }
}
