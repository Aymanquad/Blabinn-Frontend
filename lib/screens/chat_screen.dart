import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/premium_service.dart';
import '../widgets/chat_bubble.dart';
import 'media_folder_screen.dart';
import '../services/background_image_service.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _typingTimer;
  String? _errorMessage;
  String? _currentUserId;
  String? _friendId;
  String? _connectionStatus; // Add connection status tracking

  // Stream subscriptions for real-time events
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Message>? _messageSentSubscription;
  StreamSubscription<SocketEvent>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadHistory();
    _setupRealtimeListeners();
  }

  Future<void> _initializeAndLoadHistory() async {
    await _initializeCurrentUser();
    await _loadChatHistory();
    await _connectToRealtimeChat();
    await _checkConnectionStatus(); // Add connection status check
    // After loading chat history, check for last image from friend
    _checkAndSaveLastFriendImage();
  }

  Future<void> _initializeCurrentUser() async {
    _currentUserId = await _apiService.getCurrentUserId();
    print('🔍 DEBUG: Current user ID set to: $_currentUserId');

    // Get friend ID for this chat
    if (widget.chat.isFriendChat) {
      try {
        _friendId =
            widget.chat.participantIds.firstWhere((id) => id != _currentUserId);
      } catch (e) {
        _friendId = widget.chat.id;
      }
    }
    print('🔍 DEBUG: Friend ID set to: $_friendId');
  }

  // Add method to check connection status
  Future<void> _checkConnectionStatus() async {
    if (_friendId == null) return;
    
    try {
      print('🔍 DEBUG: Checking connection status with $_friendId');
      final response = await _apiService.getConnectionStatus(_friendId!);
      setState(() {
        _connectionStatus = response['status'] ?? 'none';
      });
      print('🔍 DEBUG: Connection status: $_connectionStatus');
    } catch (e) {
      print('🚨 DEBUG: Error checking connection status: $e');
      setState(() {
        _connectionStatus = 'none';
      });
    }
  }

  // Add getter to check if messaging is allowed
  bool get _canSendMessages {
    return _connectionStatus == 'accepted';
  }

  Future<void> _connectToRealtimeChat() async {
    print('🔌 DEBUG: Connecting to socket service...');
    final authService = FirebaseAuthService();
    final user = authService.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        await _socketService.connect(token);
      }
    }
  }

  void _setupRealtimeListeners() {
    // Listen for incoming messages
    _messageSubscription = _socketService.messageStream.listen((message) {
      print('💬 DEBUG: Received real-time message: ${message.content}');

      // Add the message if it's for this chat (either from friend or current user)
      if (widget.chat.isFriendChat && 
          (message.senderId == _friendId || message.receiverId == _friendId)) {
        
        // Check if this message already exists to avoid duplicates
        bool messageExists = _messages.any((msg) => msg.id == message.id);
        
        if (!messageExists) {
        setState(() {
          _messages.add(message);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        _scrollToBottom();
        
        // Note: Image auto-saving is now handled globally by BackgroundImageService
        // through the SocketService, so no need to handle it here specifically
        }
      }
    });

    // Listen for socket events
    _errorSubscription = _socketService.eventStream.listen((event) {
      switch (event) {
        case SocketEvent.message:
          print('📨 DEBUG: New message event received');
          break;
        case SocketEvent.error:
          print('🚨 DEBUG: Socket error event');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error occurred'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case SocketEvent.disconnect:
          print('🔌 DEBUG: Socket disconnected');
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 DEBUG: _loadChatHistory() called');
      Map<String, dynamic> response;

      // Check if this is a friend chat (direct messaging)
      if (widget.chat.isFriendChat) {
        // Use direct friend messaging API
        final currentUserId = await _apiService.getCurrentUserId();
        print('🔍 DEBUG: Current user ID: $currentUserId');

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

        print('🔍 DEBUG: Friend ID: $friendId');

        if (friendId == null || friendId.isEmpty) {
          throw Exception('Invalid friend ID');
        }

        print(
            '🔍 DEBUG: Calling getChatHistoryWithUser with friendId: $friendId');
        response = await _apiService.getChatHistoryWithUser(friendId!);
        print('🔍 DEBUG: Chat history response: $response');
      } else {
        // Use room-based messaging (legacy)
        response = await _apiService.getChatMessages(widget.chat.id);
      }

      final messagesData = response['messages'] as List;
      print('🔍 DEBUG: Found ${messagesData.length} messages in history');

      setState(() {
        try {
          // Sort messages by timestamp (oldest first for chat display)
          print('🔍 DEBUG: Parsing ${messagesData.length} messages...');
          final messages = <Message>[];

          for (int i = 0; i < messagesData.length; i++) {
            try {
              final message = Message.fromJson(messagesData[i]);
              messages.add(message);
              print('🔍 DEBUG: Parsed message ${i + 1}: ${message.content}');
            } catch (e) {
              print('🚨 DEBUG: Error parsing message ${i + 1}: $e');
              print('🚨 DEBUG: Message data: ${messagesData[i]}');
            }
          }

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _messages = messages;
          _isLoading = false;
          print('🔍 DEBUG: Successfully parsed ${messages.length} messages');
        } catch (e) {
          print('🚨 DEBUG: Error in message parsing: $e');
          _isLoading = false;
        }
      });

      print('🔍 DEBUG: Set ${_messages.length} messages in state');
      // Scroll to bottom after loading messages
      _scrollToBottom();
      // After loading messages, check for last friend image
      _checkAndSaveLastFriendImage();
    } catch (e) {
      print('🚨 DEBUG: _loadChatHistory error: $e');
      setState(() {
        _errorMessage = 'Failed to load chat history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _checkAndSaveLastFriendImage() async {
    if (_messages.isEmpty || _friendId == null) return;
    // Find the last message from the friend
    Message? lastFriendMessage;
    try {
      lastFriendMessage = _messages.lastWhere((msg) => msg.senderId == _friendId);
    } catch (e) {
      lastFriendMessage = null;
    }
    if (lastFriendMessage != null &&
        lastFriendMessage.type == MessageType.image &&
        lastFriendMessage.imageUrl != null &&
        lastFriendMessage.imageUrl!.isNotEmpty) {
      // Check if already received
      final alreadyReceived = await BackgroundImageService.isImageAlreadyReceived(
        imageUrl: lastFriendMessage.imageUrl!,
        messageId: lastFriendMessage.id,
      );
      if (!alreadyReceived) {
        // Save the image (this will check again inside for race conditions)
        await BackgroundImageService().handleReceivedImageMessage(lastFriendMessage, senderName: widget.chat.displayName);
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty || _isSending) return;

    if (_friendId == null) {
      print('❌ DEBUG: Cannot send message - friendId is null');
      return;
    }

    // Check if messaging is allowed based on connection status
    if (!_canSendMessages) {
      print('❌ DEBUG: Cannot send message - connection status: $_connectionStatus');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send message - friendship was removed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      print('📤 DEBUG: Sending message via real-time service');
      print('📤 DEBUG: Friend ID: $_friendId');
      print('📤 DEBUG: Message content: $messageContent');

      // Send message via socket service
      await _socketService.sendFriendMessage(_friendId!, messageContent);

      setState(() {
        _isSending = false;
      });

      _messageController.clear();
      _stopTyping();
      
      // The message will be received via socket and added to the UI automatically
    } catch (e) {
      print('🚨 DEBUG: Error sending message: $e');
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
  }

  void _startTyping() {
    setState(() {
      _isTyping = true;
    });

    // Send typing indicator via real-time service
    if (_friendId != null) {
      // Note: Typing indicator functionality can be added to SocketService if needed
      print('🔄 DEBUG: Typing indicator - would send to $_friendId');
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
        print('🔄 DEBUG: Stop typing indicator - would send to $_friendId');
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      // Show connection status when not accepted
                      if (_connectionStatus != null && _connectionStatus != 'accepted') ...[
                        Icon(
                          Icons.person_remove,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Friendship removed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ] else if (_isTyping) ...[
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
                  await _blockUser();
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
                    ? _buildEmptyState()
                    : _buildMessageList()),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin chatting!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        
        return ChatBubble(
          message: message,
          currentUserId: _currentUserId,
        );
      },
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isMessagingDisabled = !_canSendMessages;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Show warning message when messaging is disabled
          if (isMessagingDisabled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Friendship was removed. You can view chat history but cannot send new messages.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file, 
                  color: isMessagingDisabled 
                    ? theme.colorScheme.onSurface.withOpacity(0.3)
                    : theme.colorScheme.onSurface
                ),
                onPressed: isMessagingDisabled ? null : () {
                  _showAttachmentOptions();
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onChanged: isMessagingDisabled ? null : _onMessageChanged,
                  enabled: !isMessagingDisabled,
                  decoration: InputDecoration(
                    hintText: isMessagingDisabled 
                      ? 'Messaging disabled'
                      : AppStrings.typeMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isMessagingDisabled 
                      ? theme.colorScheme.surface.withOpacity(0.5)
                      : theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isMessagingDisabled 
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: isMessagingDisabled ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkChatImageSending(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }
    
    try {
      print('📸 DEBUG: Starting camera capture');
      
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showError('Camera permission is required to take photos');
        
        // Check if permission is permanently denied
        if (status == PermissionStatus.permanentlyDenied) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text('Please grant camera permission in app settings to take photos.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _showImageConfirmation(File(image.path));
      }
    } catch (e) {
      print('❌ DEBUG: Camera capture error: $e');
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkChatImageSending(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }
    
    try {
      print('🖼️ DEBUG: Starting gallery picker');
      
      // Request storage permission (use photos permission for Android 13+)
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
      
      if (status != PermissionStatus.granted) {
        _showError('Gallery permission is required to select photos');
        
        // Check if permission is permanently denied
        if (status == PermissionStatus.permanentlyDenied) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Gallery Permission Required'),
              content: const Text('Please grant gallery permission in app settings to select photos.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _showImageConfirmation(File(image.path));
      }
    } catch (e) {
      print('❌ DEBUG: Gallery picker error: $e');
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _showImageConfirmation(File imageFile) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Send Image?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
                maxWidth: 300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _sendImageMessage(imageFile);
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (_friendId == null) {
      print('❌ DEBUG: Cannot send image - friendId is null');
      return;
    }

    // Check if messaging is allowed based on connection status
    if (!_canSendMessages) {
      print('❌ DEBUG: Cannot send image - connection status: $_connectionStatus');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send image - friendship was removed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      print('📤 DEBUG: Uploading and sending image');

      // Upload image to backend
      final imageUrl = await _apiService.uploadChatImage(imageFile);
      
      // Save image to media folder
      await _saveImageToMediaFolder(imageFile);

      // Send image message via socket service
      await _socketService.sendFriendImageMessage(_friendId!, imageUrl);

      setState(() {
        _isSending = false;
      });

      // The message will be received via socket and added to the UI automatically
      _showSuccess('Image sent successfully!');
    } catch (e) {
      print('🚨 DEBUG: Error sending image: $e');
      setState(() {
        _isSending = false;
      });
      _showError('Failed to send image: $e');
    }
  }

  Future<void> _saveImageToMediaFolder(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');
      
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_sent.jpg';
      final savedFile = File('${mediaDir.path}/$fileName');
      
      await imageFile.copy(savedFile.path);
      print('✅ DEBUG: Sent image saved to media folder');
    } catch (e) {
      print('⚠️ DEBUG: Failed to save sent image to media folder: $e');
    }
  }



  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showAttachmentOptions() {
    // Don't show attachment options if messaging is disabled
    if (!_canSendMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send attachments - friendship was removed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement location sharing
              },
            ),
          ],
        ),
      ),
    );
  }



  /// Block the current friend user
  Future<void> _blockUser() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block User'),
          content: Text('Are you sure you want to block ${widget.chat.name}? You will no longer be able to see their messages or find them in search.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && _friendId != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Block the user using UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final success = await userProvider.blockUser(_friendId!);

        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.chat.name} has been blocked'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to previous screen
          Navigator.pop(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to block user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error blocking user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
