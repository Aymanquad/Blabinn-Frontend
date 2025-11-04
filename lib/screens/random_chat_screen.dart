import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/chat_moderation_service.dart';
import '../services/premium_service.dart';
import '../utils/permission_helper.dart';
import '../models/message.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../utils/html_decoder.dart';

class RandomChatScreen extends StatefulWidget {
  final String sessionId;
  final String chatRoomId;
  final bool isAIChat;
  final String? aiPersonality;

  const RandomChatScreen({
    super.key,
    required this.sessionId,
    required this.chatRoomId,
    this.isAIChat = false,
    this.aiPersonality,
  });

  @override
  State<RandomChatScreen> createState() => _RandomChatScreenState();
}

class _RandomChatScreenState extends State<RandomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  late SocketService _socketService;
  late ApiService _apiService;
  final ChatModerationService _moderationService = ChatModerationService();
  final ImagePicker _imagePicker = ImagePicker();
  late StreamSubscription<dynamic> _messageSubscription;
  late StreamSubscription<String> _errorSubscription;
  late StreamSubscription<SocketEvent> _eventSubscription;
  bool _isSessionActive = true;
  bool _hasShownEndDialog = false; // Prevent multiple dialogs
  bool _isDisposing = false; // Prevent multiple dispose calls
  bool _isSocketConnected = true; // Track socket connection status
  Timer? _heartbeatTimer;
  Map<String, dynamic>? _partnerInfo;
  bool _isLoadingPartnerInfo = false;

  @override
  void initState() {
    super.initState();
    
    print('🔥🔥🔥 [INIT] RandomChatScreen initState called');
    print('🔥🔥🔥 [INIT] isAIChat: ${widget.isAIChat}');
    print('🔥🔥🔥 [INIT] aiPersonality: ${widget.aiPersonality}');
    print('🔥🔥🔥 [INIT] sessionId: ${widget.sessionId}');
    print('🔥🔥🔥 [INIT] chatRoomId: ${widget.chatRoomId}');
    
    // For AI chats, create AI partner info FIRST before anything else
    if (widget.isAIChat) {
      print('🔥🔥🔥 [INIT] Creating AI partner info...');
      _createAIPartnerInfo();
      print('🔥🔥🔥 [INIT] _partnerInfo after creation: $_partnerInfo');
    } else {
      print('🔥🔥🔥 [INIT] NOT an AI chat, will load regular partner info');
    }
    
    _initializeServices();
    _validateSession();
    _setupSocketListeners();
    _joinChatRoom();
    _startHeartbeat();
    _startSessionTimeout();

    // Load partner info with a delay for non-AI chats
    if (!widget.isAIChat) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadPartnerInfo();
        }
      });
    }
  }

  void _validateSession() {
    // Validate that we have proper session data
    if (widget.sessionId.isEmpty || widget.chatRoomId.isEmpty) {
      print('❌ [RANDOM CHAT DEBUG] Invalid session data');
      _showSessionErrorDialog('Invalid session data. Please try again.');
      return;
    }

    print('✅ [RANDOM CHAT DEBUG] Session validated');
    print('   📱 Session ID: ${widget.sessionId}');
    print('   💬 Chat Room ID: ${widget.chatRoomId}');
  }

  void _showSessionErrorDialog(String message) {
    if (!mounted || _hasShownEndDialog) return;

    _hasShownEndDialog = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Session Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _safeNavigateBack();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isDisposing) {
      print('🚪 [RANDOM CHAT DEBUG] Already disposing, skipping');
      return;
    }

    _isDisposing = true;
    print('🚪 [RANDOM CHAT DEBUG] Starting dispose cleanup');

    // Set session as inactive to prevent new operations
    _isSessionActive = false;

    // Cancel all subscriptions first
    _cleanupListeners();

    // Stop all timers
    _stopHeartbeat();

    // Perform cleanup operations
    _performCleanup();

    // Dispose controllers
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
    print('🚪 [RANDOM CHAT DEBUG] Dispose cleanup completed');
  }

  void _scrollToBottom() {
    // Use multiple attempts to ensure scrolling works
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Second attempt with longer delay in case first one fails
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeServices() {
    _socketService = SocketService();
    _apiService = ApiService();
  }

  void _setupSocketListeners() {
    _messageSubscription =
        _socketService.messageStream.listen(_handleNewMessage);
    _errorSubscription = _socketService.errorStream.listen(_handleError);
    _eventSubscription = _socketService.eventStream.listen((event) {
      print('📡 [RANDOM CHAT DEBUG] Socket event received: $event');

      // Prevent handling events if session is already ended
      if (!_isSessionActive) {
        print('📡 [RANDOM CHAT DEBUG] Ignoring event - session already ended');
        return;
      }

      switch (event) {
        case SocketEvent.connect:
          print('✅ [RANDOM CHAT DEBUG] Socket connected - rejoining chat room');
          setState(() {
            _isSocketConnected = true;
          });
          _joinChatRoom();
          break;
        case SocketEvent.disconnect:
          print('⚠️ [RANDOM CHAT DEBUG] Socket disconnected - will auto-reconnect');
          setState(() {
            _isSocketConnected = false;
          });
          break;
        case SocketEvent.error:
          print('❌ [RANDOM CHAT DEBUG] Socket error - will attempt reconnect');
          setState(() {
            _isSocketConnected = false;
          });
          break;
        case SocketEvent.randomChatSessionEnded:
          print('🚪 [RANDOM CHAT DEBUG] Session ended by other user');
          _handlePartnerEndedSession();
          break;
        case SocketEvent.randomConnectionStopped:
          print(
              '🚪 [RANDOM CHAT DEBUG] Random connection stopped by other user');
          _handlePartnerEndedSession();
          break;
        case SocketEvent.randomChatEvent:
          print('🎯 [RANDOM CHAT DEBUG] Random chat event received');
          // Handle other random chat events if needed
          break;
        default:
          print('📡 [RANDOM CHAT DEBUG] Unhandled socket event: $event');
          break;
      }
    });
  }

  void _joinChatRoom() {
    try {
      _socketService.joinChat(widget.chatRoomId);
      print('🔌 [RANDOM CHAT DEBUG] Joined chat room: ${widget.chatRoomId}');

      // Add a timeout to check if we actually joined the room
      Timer(const Duration(seconds: 15), () {
        if (mounted && _messages.isEmpty && _isSessionActive) {
          print('⚠️ [RANDOM CHAT DEBUG] No messages received after 15 seconds');
          _checkSessionStatus();
        }
      });
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Failed to join chat room: $e');
      _showSessionErrorDialog('Failed to join chat room. Please try again.');
    }
  }

  void _checkSessionStatus() {
    // Check if the session is still valid
    if (!_isSessionActive) return;

    print('🔍 [RANDOM CHAT DEBUG] Checking session status...');

    // Don't show error just because there are no messages
    // Messages might not have been sent yet, but the session could still be active
    // Only show error if we have explicit session end events
    print('🔍 [RANDOM CHAT DEBUG] Session appears to be active, continuing...');
  }

  void _cleanupListeners() {
    try {
      _messageSubscription.cancel();
      print('✅ [RANDOM CHAT DEBUG] Message subscription cancelled');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error cancelling message subscription: $e');
    }

    try {
      _errorSubscription.cancel();
      print('✅ [RANDOM CHAT DEBUG] Error subscription cancelled');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error cancelling error subscription: $e');
    }

    try {
      _eventSubscription.cancel();
      print('✅ [RANDOM CHAT DEBUG] Event subscription cancelled');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error cancelling event subscription: $e');
    }
  }

  Future<void> _performCleanup() async {
    print('🧹 [RANDOM CHAT DEBUG] Performing comprehensive cleanup');

    // Execute cleanup operations
    try {
      _leaveChatRoom();
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Leave chat room failed: $e');
    }

    try {
      _stopRandomConnection();
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Stop random connection failed: $e');
    }

    try {
      _clearActiveSession();
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Clear active session failed: $e');
    }

    print('✅ [RANDOM CHAT DEBUG] Cleanup operations completed');
  }

  Future<void> _leaveChatRoom() async {
    if (!_isSessionActive) return;

    try {
      await _socketService.leaveChat(widget.chatRoomId);
      print('✅ [RANDOM CHAT DEBUG] Left chat room successfully');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error leaving chat room: $e');
    }
  }

  Future<void> _stopRandomConnection() async {
    if (!_isSessionActive) return;

    try {
      await _socketService.stopRandomConnection();
      print('✅ [RANDOM CHAT DEBUG] Stopped random connection');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error stopping random connection: $e');
    }
  }

  Future<void> _clearActiveSession() async {
    if (!_isSessionActive) return;

    try {
      await _apiService.forceClearActiveSession();
      print('✅ [RANDOM CHAT DEBUG] Force cleared active session via API');
    } catch (e) {
      print('⚠️ [RANDOM CHAT DEBUG] Error force clearing session: $e');
    }
  }

  void _handleNewMessage(dynamic message) async {
    if (!mounted) return;

    print('🎉 [HANDLE NEW MESSAGE] Received message in screen handler');
    print('   📋 Message ID: ${message.id}');
    print('   👤 Sender ID: ${message.senderId}');
    print('   💬 Content: ${message.content}');
    print('   📝 Type: ${message.type}');

    final messageId =
        message.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final messageContent =
        HtmlDecoder.decodeHtmlEntities(message.content?.toString() ?? '');
    final messageSenderId = message.senderId ?? '';

    // Apply moderation to received message content
    final moderatedContent =
        _moderationService.moderateReceivedMessage(messageContent);

    // Get current user ID from Firebase Auth
    String? currentUserId;
    try {
      final user = FirebaseAuth.FirebaseAuth.instance.currentUser;
      currentUserId = user?.uid;
      //print('🔍 [RANDOM CHAT DEBUG] Current user ID: $currentUserId');
      //print('🔍 [RANDOM CHAT DEBUG] Message sender ID: $messageSenderId');
    } catch (e) {
      //print('❌ [RANDOM CHAT DEBUG] Error getting current user: $e');
    }

    // Check if this is a message from the current user
    // For AI chats, messages from 'ai_bot' are from the partner (not current user)
    final isFromCurrentUser = messageSenderId != 'ai_bot' && 
        (currentUserId != null && messageSenderId == currentUserId);

    //print('🔍 [RANDOM CHAT DEBUG] Is from current user: $isFromCurrentUser');

    // Check if we have a temporary message with the same content from current user
    final tempMessageIndex = _messages.indexWhere((msg) =>
        msg['content'] == moderatedContent &&
        msg['isFromCurrentUser'] == true &&
        msg['id'].toString().startsWith('temp_'));

    if (tempMessageIndex != -1 && isFromCurrentUser) {
      // Replace temporary message with real message
      //print(
      // '🔄 [RANDOM CHAT DEBUG] Replacing temp message with real message: $messageId');
      setState(() {
        _messages[tempMessageIndex] = {
          'id': messageId,
          'content': moderatedContent,
          'senderId': messageSenderId,
          'timestamp': message.timestamp ?? DateTime.now(),
          'isFromCurrentUser': true,
        };
      });
    } else {
      // Check if this message is already in the UI
      final existingMessageIndex =
          _messages.indexWhere((msg) => msg['id'] == messageId);

      if (existingMessageIndex != -1) {
        //print(
        // '⏭️ [RANDOM CHAT DEBUG] Message already in UI, skipping: $messageId');
        return;
      }

      // Add new message
      print('➕ [HANDLE NEW MESSAGE] Adding new message to UI');
      print('   🆔 Message ID: $messageId');
      print('   👤 Sender: $messageSenderId');
      print('   📝 Content: ${moderatedContent.substring(0, moderatedContent.length > 50 ? 50 : moderatedContent.length)}...');
      print('   🔵 Is from current user: $isFromCurrentUser');
      
      setState(() {
        final newMessage = {
          'id': messageId,
          'content': moderatedContent,
          'senderId': messageSenderId,
          'timestamp': message.timestamp ?? DateTime.now(),
          'isFromCurrentUser': isFromCurrentUser,
          'type': message.type?.name ?? 'text',
          'imageUrl': message.imageUrl,
        };
        print('🔥🔥🔥 [CRITICAL] About to add message to _messages array:');
        print('   isFromCurrentUser: ${newMessage['isFromCurrentUser']}');
        print('   senderId: ${newMessage['senderId']}');
        print('   content: ${newMessage['content']}');
        _messages.add(newMessage);
        print('🔥🔥🔥 [CRITICAL] Message added! _messages.length is now: ${_messages.length}');
        print('🔥🔥🔥 [CRITICAL] Last message in array: ${_messages.last}');
      });

      print('✅ [HANDLE NEW MESSAGE] Message added to UI! Total messages: ${_messages.length}');
      _scrollToBottom();

      // Load partner info if we haven't already and this is from partner
      if (!isFromCurrentUser && _partnerInfo == null) {
        _loadPartnerInfo();
      }

      //print(
      // '✅ [RANDOM CHAT DEBUG] Added new message to UI: $messageContent (from current user: $isFromCurrentUser)');
    }
  }

  void _handleError(String error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handlePartnerEndedSession() {
    if (!mounted || !_isSessionActive) {
      print(
          '🚪 [RANDOM CHAT DEBUG] Ignoring partner ended session - already handled');
      return;
    }

    print('🚪 [RANDOM CHAT DEBUG] Partner ended session, handling locally');

    setState(() {
      _isSessionActive = false;
    });

    _stopHeartbeat();
    _leaveChatRoom();

    // Show partner left dialog only once
    if (mounted) {
      _showSessionEndDialog('partner_left');
    }
  }

  /// Get a user-friendly display name for a user ID
  Future<String> _getUserDisplayName(String userId) async {
    try {
      final userProfile = await _apiService.getUserProfile(userId);
      if (userProfile['displayName'] != null) {
        return userProfile['displayName'] as String;
      }
    } catch (e) {
      print('⚠️ Failed to get user profile for $userId: $e');
    }

    // Fallback: create a friendly name from user ID
    if (userId.length > 8) {
      return 'User ${userId.substring(0, 8)}...';
    }
    return 'User $userId';
  }

  /// Build display name with age for better visibility
  String _buildDisplayNameWithAge() {
    if (_partnerInfo == null) return 'Loading...';
    
    final displayName =
        (_partnerInfo!['displayName'] as String?) ?? 'Anonymous';
    final age = _partnerInfo!['age'];

    if (age != null && age is int) {
      return '$displayName, $age';
    }
    return displayName;
  }

  void _createAIPartnerInfo() {
    // Create AI partner info based on personality
    final personality = widget.aiPersonality ?? 'general-assistant';
    final personalityName = personality.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
    
    print('🤖 [AI CHAT] Creating AI partner info with personality: $personality');
    
    // Directly set values without setState during initState
    _partnerInfo = {
      'id': 'ai_bot',
      'displayName': 'AI Chat Partner',
      'profilePictureUrl': null,
      'age': null,
      'gender': 'AI',
      'bio': 'I\'m an AI assistant here to chat with you! My personality is $personalityName.',
      'isOnline': true,
      'isAIChat': true,
      'aiPersonality': personality,
    };
    _isLoadingPartnerInfo = false;
    
    print('✅ [AI CHAT] AI partner info created');
  }

  Future<void> _loadPartnerInfo() async {
    if (_isLoadingPartnerInfo) return;

    setState(() {
      _isLoadingPartnerInfo = true;
    });

    try {
      // Get current user ID
      final currentUserId = FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No current user ID found');
        setState(() {
          _isLoadingPartnerInfo = false;
        });
        return;
      }

      print('🔍 Loading partner info for user: $currentUserId');

      // Try multiple methods to get partner ID
      String? partnerId;

      // Method 1: Try to get partner ID from messages
      for (final message in _messages) {
        final senderId = message['senderId'] as String?;
        if (senderId != null &&
            senderId != currentUserId &&
            senderId != 'current_user') {
          partnerId = senderId;
          print('🔍 Found partner ID from messages: $partnerId');
          break;
        }
      }

      // Method 2: If no partner found in messages, try to get from active session
      if (partnerId == null) {
        print(
            '🔍 No partner found in messages, trying to get from active session...');
        try {
          final responseData = await _apiService.getActiveRandomChatSession();
          final sessionData = responseData['session'] as Map<String, dynamic>?;
          if (sessionData != null &&
              sessionData['sessionId'] == widget.sessionId) {
            // First try the direct partnerId field (for backward compatibility)
            partnerId = sessionData['partnerId'] as String?;

            // If no direct partnerId, extract from participants array
            if (partnerId?.isEmpty != false) {
              final participants =
                  sessionData['participants'] as List<dynamic>?;
              if (participants != null && participants.isNotEmpty) {
                // Find the participant that is not the current user
                for (final participant in participants) {
                  if (participant != currentUserId) {
                    partnerId = participant as String?;
                    break;
                  }
                }
              }
            }

            if (partnerId != null) {
              print('🔍 Found partner ID from active session: $partnerId');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get active session: $e');
        }
      }

      // Method 3: If still no partner, try to get partner from session data directly
      if (partnerId == null) {
        print(
            '🔍 No partner found in messages or active session, trying alternative methods...');
        try {
          // Try to get partner info from the session itself
          final responseData = await _apiService.getActiveRandomChatSession();
          final sessionData = responseData['session'] as Map<String, dynamic>?;
          if (sessionData != null && sessionData.isNotEmpty) {
            // Try different possible field names for partner info
            partnerId = (sessionData['partnerId'] as String?) ??
                (sessionData['partner_id'] as String?) ??
                (sessionData['otherUserId'] as String?) ??
                (sessionData['other_user_id'] as String?);

            // If still no partnerId, try extracting from participants array
            if (partnerId?.isEmpty != false) {
              final participants =
                  sessionData['participants'] as List<dynamic>?;
              if (participants != null && participants.isNotEmpty) {
                // Find the participant that is not the current user
                for (final participant in participants) {
                  if (participant != currentUserId) {
                    partnerId = participant as String?;
                    break;
                  }
                }
              }
            }

            if (partnerId != null) {
              print('🔍 Found partner ID from session data: $partnerId');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get session data: $e');
        }

        // If still no partner, create a generic partner info
        if (partnerId == null) {
          print('ℹ️ No partner found, creating generic partner info');
          setState(() {
            _partnerInfo = {
              'id': 'random_partner_${DateTime.now().millisecondsSinceEpoch}',
              'displayName': 'Random Partner',
              'profilePictureUrl': null,
              'age': null,
              'gender': 'Other',
              'bio': 'You\'re connected with a random chat partner!',
              'isOnline': true,
              'isRandomPartner': true,
            };
          });
          setState(() {
            _isLoadingPartnerInfo = false;
          });
          return;
        }
      }

      // Get partner profile
      print('🔍 Fetching profile for partner: $partnerId');
      final partnerProfile = await _apiService.getUserProfile(partnerId);
      print('🔍 [PARTNER DEBUG] Raw partner profile: $partnerProfile');

      if (partnerProfile.isNotEmpty) {
        print('✅ Partner profile loaded: ${partnerProfile['displayName']}');
        print(
            '🔍 [PARTNER DEBUG] Partner ID in profile: ${partnerProfile['id']}');

        // Ensure the ID field is properly set
        final profileWithId = Map<String, dynamic>.from(partnerProfile);
        if (profileWithId['id'] == null ||
            profileWithId['id'].toString().isEmpty) {
          profileWithId['id'] = partnerId;
          print('🔍 [PARTNER DEBUG] Fixed missing ID field with: $partnerId');
        }

        setState(() {
          _partnerInfo = profileWithId;
        });
      } else {
        print('⚠️ Partner profile not found, creating basic profile');
        final displayName = await _getUserDisplayName(partnerId);
        setState(() {
          _partnerInfo = {
            'id': partnerId,
            'displayName': displayName,
            'profilePictureUrl': null,
            'age': null,
            'gender': null,
            'bio': null,
            'isOnline': true,
          };
        });
      }

      setState(() {
        _isLoadingPartnerInfo = false;
      });
    } catch (e) {
      print('❌ Failed to load partner info: $e');
      // Create a fallback partner info
      setState(() {
        _partnerInfo = {
          'id': 'fallback_partner_${DateTime.now().millisecondsSinceEpoch}',
          'displayName': 'Random Chat Partner',
          'profilePictureUrl': null,
          'age': null,
          'gender': 'Other',
          'bio':
              'You\'re connected with a random chat partner! Start chatting to get to know each other.',
          'isOnline': true,
          'isRandomPartner': true,
        };
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPartnerInfo = false;
        });
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSessionActive) {
        timer.cancel();
        return;
      }
      // Send heartbeat to maintain session
      _sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    // Send heartbeat via socket or API to maintain session activity
    // This would depend on your implementation
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || !_isSessionActive || !_isSocketConnected) {
      if (!_isSocketConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot send message: WebSocket not connected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // Process message through moderation service
      final processedContent =
          await _moderationService.processMessageForSending(context, content);

      if (processedContent == null) {
        // User cancelled sending due to inappropriate content
        return;
      }

      // Add message to UI immediately (optimistic update)
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.add({
          'id': tempMessageId,
          'content': processedContent,
          'senderId':
              'current_user', // Will be updated when we get the real message
          'timestamp': DateTime.now(),
          'isFromCurrentUser': true,
          'type': 'text',
        });
      });

      _scrollToBottom();

      //print('📤 [RANDOM CHAT DEBUG] Added optimistic message to UI: $processedContent');

      _messageController.clear();

      // Send processed message via socket
      await _socketService.sendMessage(
        widget.chatRoomId,
        processedContent,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Image sharing methods
  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
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
          ],
        ),
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
      // Request camera permission
      final hasPermission =
          await PermissionHelper.requestCameraPermission(context);
      if (!hasPermission) {
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
      // Request gallery permission
      final hasPermission =
          await PermissionHelper.requestGalleryPermission(context);
      if (!hasPermission) {
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
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _showImageConfirmation(File imageFile) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Send Image?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to send this image?',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    );

    if (confirmed == true) {
      await _sendImageMessage(imageFile);
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (!_isSessionActive) return;

    try {
      // Upload image to backend
      final imageUrl = await _apiService.uploadChatImage(imageFile);

      // Add image message to UI immediately (optimistic update)
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.add({
          'id': tempMessageId,
          'content': '', // No text content for image messages
          'senderId': 'current_user',
          'timestamp': DateTime.now(),
          'isFromCurrentUser': true,
          'type': 'image',
          'imageUrl': imageUrl,
        });
      });

      _scrollToBottom();

      // Send image message via socket
      await _socketService.sendMessage(
        widget.chatRoomId,
        imageUrl,
        type: MessageType.image,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to send image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isFromCurrentUser) {
    final messageType = message['type'] as String? ?? 'text';

    if (messageType == 'image') {
      return _buildImageMessage(message, isFromCurrentUser);
    } else {
      return _buildTextMessage(message, isFromCurrentUser);
    }
  }

  Widget _buildTextMessage(
      Map<String, dynamic> message, bool isFromCurrentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            isFromCurrentUser ? AppColors.primary : AppColors.receivedMessage,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        HtmlDecoder.decodeHtmlEntities(message['content'] as String),
        style: TextStyle(
          color: isFromCurrentUser ? Colors.white : AppColors.text,
        ),
      ),
    );
  }

  Widget _buildImageMessage(
      Map<String, dynamic> message, bool isFromCurrentUser) {
    final imageUrl = message['imageUrl'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildTextMessage({'content': '[Image]'}, isFromCurrentUser);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isFromCurrentUser ? AppColors.primary : AppColors.receivedMessage,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Image.network(
            imageUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionEndDialog(String reason) {
    // Prevent multiple dialogs
    if (_hasShownEndDialog) {
      print('🚪 [RANDOM CHAT DEBUG] End dialog already shown, skipping');
      return;
    }

    _hasShownEndDialog = true;

    String title = 'Chat Ended';
    String message = 'The chat session has ended.';
    IconData icon = Icons.chat_bubble_outline;

    switch (reason) {
      case 'timeout':
        title = 'Session Ended';
        message = 'The chat session has ended.';
        icon = Icons.timer;
        break;
      case 'user_ended':
        title = 'Chat Ended';
        message = 'You ended the chat session.';
        icon = Icons.person_off;
        break;
      case 'partner_left':
        title = 'Partner Left';
        message = 'Your chat partner has left the conversation.';
        icon = Icons.person_off;
        break;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _safeNavigateBack();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAsFriend() async {
    if (_partnerInfo == null) return;

    // Handle different user types
    if (_partnerInfo!['isPlaceholder'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Connect with people through chat to add them as friends!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_partnerInfo!['isRandomPartner'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You can add random chat partners as friends after getting to know them better!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_partnerInfo!['isConnectedFriend'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This person is already your friend!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_partnerInfo!['isDemo'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This is a demo user. Connect with real people to add them as friends!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // For real users, send friend request
    await _sendFriendRequest();
  }

  Future<void> _sendFriendRequest() async {
    if (_partnerInfo == null) {
      print('❌ [FRIEND REQUEST DEBUG] Partner info is null');
      return;
    }

    print('🔍 [FRIEND REQUEST DEBUG] Partner info: $_partnerInfo');

    try {
      final partnerId = _partnerInfo!['id'];
      print(
          '🔍 [FRIEND REQUEST DEBUG] Partner ID: $partnerId (type: ${partnerId.runtimeType})');

      // Check if partnerId is null or not a string
      if (partnerId == null || partnerId is! String) {
        print('❌ [FRIEND REQUEST DEBUG] Partner ID is invalid: $partnerId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to send friend request: Partner information is incomplete.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check if this is a demo/mock user
      if (partnerId.startsWith('mock_partner_') ||
          partnerId.startsWith('demo_partner_') ||
          _partnerInfo!['isDemo'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This is a demo user. Friend requests can only be sent to real users in active chat sessions.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check current connection status before sending request
      print(
          '🔍 [FRIEND REQUEST DEBUG] Checking connection status for $partnerId');
      final connectionStatus = await _apiService.getConnectionStatus(partnerId);
      print('🔍 [FRIEND REQUEST DEBUG] Connection status: $connectionStatus');

      final status = connectionStatus['status'] ?? 'none';
      if (status == 'friends' || status == 'accepted') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already friends with this user!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (status == 'pending') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend request already sent and is pending.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      print('🔍 [FRIEND REQUEST DEBUG] Sending friend request to $partnerId');
      await _apiService.sendFriendRequest(
        partnerId,
        message: 'Hi! I met you in a random chat and would like to connect.',
        type: 'random_chat',
      );

      print('✅ [FRIEND REQUEST DEBUG] Friend request sent successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [FRIEND REQUEST DEBUG] Failed to send friend request: $e');
      if (mounted) {
        String errorMessage = 'Failed to send friend request';
        Color backgroundColor = Colors.red;

        // Provide more specific error messages
        if (e.toString().contains('Friend request already sent')) {
          errorMessage = 'Friend request already sent to this user';
          backgroundColor = Colors.orange;
        } else if (e.toString().contains('Already friends')) {
          errorMessage = 'You are already friends with this user!';
          backgroundColor = Colors.green;
        } else if (e.toString().contains('User not found')) {
          errorMessage =
              'User not found. They may have left the chat or their account is no longer active.';
          backgroundColor = Colors.orange;
        } else if (e.toString().contains('Request already sent')) {
          errorMessage = 'Friend request already sent to this user.';
          backgroundColor = Colors.orange;
        } else {
          errorMessage =
              'Failed to send friend request. Please try again later.';
          print('❌ [FRIEND REQUEST DEBUG] Detailed error: ${e.toString()}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _navigateToPartnerProfile() {
    if (_partnerInfo == null) return;

    _showPartnerProfileModal();
  }

  void _showPartnerProfileModal() {
    if (_partnerInfo == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPartnerProfileModal(),
    );
  }

  void _showExitWarningDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('End Session?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this random chat session? This action cannot be undone.',
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
              _endSession('user_ended');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(String reason) async {
    if (!_isSessionActive) {
      print('🚪 [RANDOM CHAT DEBUG] Session already ended, skipping');
      // Even if session is already ended locally, try to clean up on backend
      await _performCleanup();
      return;
    }

    print('🚪 [RANDOM CHAT DEBUG] Ending session with reason: $reason');

    setState(() {
      _isSessionActive = false;
    });

    // Always try to end session properly first with timeout
    try {
      // End session via socket (this will notify both users)
      await _socketService
          .endRandomChatSession(widget.sessionId, reason)
          .timeout(const Duration(seconds: 5));
      print('✅ [RANDOM CHAT DEBUG] Session ended successfully via socket');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Error ending session via socket: $e');
      // If socket fails, try API fallback
      try {
        await _apiService
            .endRandomChatSession(widget.sessionId, reason: reason)
            .timeout(const Duration(seconds: 5));
        print('✅ [RANDOM CHAT DEBUG] Session ended via API fallback');
      } catch (apiError) {
        print('❌ [RANDOM CHAT DEBUG] Error ending session via API: $apiError');
      }
    }

    // Always perform local cleanup
    await _performCleanup();

    // Show end session dialog
    if (mounted) {
      _showSessionEndDialog(reason);
    }
  }

  void _safeNavigateBack() {
    // Check if we can pop safely
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If we can't pop, navigate to connect screen directly
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/connect',
        (route) => route.settings.name == '/home' || route.isFirst,
      );
    }
  }

  // Note: _forceCleanup method removed (unused)

  void _startSessionTimeout() {
    // Remove the aggressive timeout that was causing false errors
    // The session should only end when explicitly ended by users or server
    print(
        '⏰ [RANDOM CHAT DEBUG] Session timeout disabled - relying on explicit session events');
  }

  Widget _buildPartnerProfileModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addAsFriend,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  tooltip: 'Add as Friend',
                ),
              ],
            ),
          ),

          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _partnerInfo!['profilePictureUrl'] != null
                          ? Image.network(
                              _partnerInfo!['profilePictureUrl'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary
                                            .withValues(alpha: 0.3),
                                        AppColors.primary
                                            .withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    AppColors.primary.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name and Age
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _buildDisplayNameWithAge(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_partnerInfo!['isDemo'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'DEMO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ] else if (_partnerInfo!['isConnectedFriend'] ==
                          true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'FRIEND',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ] else if (_partnerInfo!['isPlaceholder'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'NO FRIENDS',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ] else if (_partnerInfo!['isAIChat'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.smart_toy, size: 12, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                'AI BOT',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_partnerInfo!['isRandomPartner'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'RANDOM',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (_partnerInfo!['age'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_partnerInfo!['age']} years old',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Online Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Online',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bio Section
                  if (_partnerInfo!['bio'] != null &&
                      (_partnerInfo!['bio'] as String).isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _partnerInfo!['bio'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.grey[300],
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Gender Section
                  if (_partnerInfo!['gender'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Gender',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            _partnerInfo!['gender'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.grey[300],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendFriendRequest,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add Friend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Continue Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨🎨🎨 [BUILD] RandomChatScreen build called');
    print('🎨🎨🎨 [BUILD] _messages.length: ${_messages.length}');
    print('🎨🎨🎨 [BUILD] _isSessionActive: $_isSessionActive');
    print('🎨🎨🎨 [BUILD] _partnerInfo is null: ${_partnerInfo == null}');
    if (_partnerInfo != null) {
      print('🎨🎨🎨 [BUILD] _partnerInfo displayName: ${_partnerInfo!['displayName']}');
      print('🎨🎨🎨 [BUILD] _partnerInfo isAIChat: ${_partnerInfo!['isAIChat']}');
    }
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Always use the unified end session method
          _showExitWarningDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Random Chat'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          automaticallyImplyLeading: false, // Disable default back button
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showExitWarningDialog,
          ),
          actions: [
            IconButton(
              icon: _isLoadingPartnerInfo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
              onPressed:
                  _partnerInfo != null ? _navigateToPartnerProfile : null,
              tooltip: 'View Partner Profile',
            ),
          ],
        ),
        body: Column(
          children: [
            // Connection Status Banner
            if (!_isSocketConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Partner Profile Section
            if (_partnerInfo != null)
              GestureDetector(
                onTap: _showPartnerProfileModal,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Profile Picture
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _partnerInfo!['profilePictureUrl'] != null
                              ? Image.network(
                                  _partnerInfo!['profilePictureUrl'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary
                                                .withValues(alpha: 0.3),
                                            AppColors.primary
                                                .withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary
                                                .withValues(alpha: 0.3),
                                            AppColors.primary
                                                .withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary
                                            .withValues(alpha: 0.3),
                                        AppColors.primary
                                            .withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _buildDisplayNameWithAge(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_partnerInfo!['isDemo'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'DEMO',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ] else if (_partnerInfo!['isConnectedFriend'] ==
                                    true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.green.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'FRIEND',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ] else if (_partnerInfo!['isPlaceholder'] ==
                                    true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'NO FRIENDS',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ] else if (_partnerInfo!['isAIChat'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.purple.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.smart_toy, size: 10, color: Colors.purple),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                color: Colors.purple,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (_partnerInfo!['isRandomPartner'] ==
                                    true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.blue.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'RANDOM',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.green.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Online',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                ),
                                if (_partnerInfo!['gender'] != null) ...[
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _partnerInfo!['gender'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
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
                ),
              )
            else
              // Loading state for partner info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Loading profile picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Loading text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 16,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Messages list
            Expanded(
              child: Container(
                color: const Color(0xFF16213E), // Dark blue background
                child: _messages.isEmpty
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
                              'Start chatting!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Say hello to your AI chat partner',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          print('🎨 [UI BUILD] Building message $index of ${_messages.length}');
                          final message = _messages[index];
                          print('   📋 Message ID: ${message['id']}');
                          print('   👤 Sender: ${message['senderId']}');
                          print('   📝 Content: ${message['content']}');
                          print('   🔵 isFromCurrentUser: ${message['isFromCurrentUser']}');
                          final isFromCurrentUser =
                              message['isFromCurrentUser'] as bool;

                          return Align(
                            alignment: isFromCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child:
                                  _buildMessageBubble(message, isFromCurrentUser),
                            ),
                          );
                        },
                      ),
              ),
            ),
            // Message input
            if (_isSessionActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Message input row
                    Row(
                      children: [
                        // Attachment button
                        IconButton(
                          onPressed: _showAttachmentOptions,
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          tooltip: 'Attach Image',
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.inputBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  suffixIcon: _messageController.text.length >
                                          900
                                      ? Icon(
                                          Icons.warning,
                                          color:
                                              _messageController.text.length >=
                                                      1000
                                                  ? Colors.red
                                                  : Colors.orange,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                                onSubmitted: (_) => _sendMessage(),
                                textInputAction: TextInputAction.send,
                                maxLines:
                                    2, // Reduced from 4 to 2 for shorter height
                                maxLength: 1000,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                              ),
                              if (_messageController.text.length > 900)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 16),
                                  child: Text(
                                    '${_messageController.text.length}/1000',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _messageController.text.length >= 1000
                                              ? Colors.red
                                              : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSocketConnected ? _sendMessage : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isSocketConnected 
                                  ? AppColors.primary 
                                  : Colors.grey.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: _isSocketConnected 
                                  ? Colors.white 
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
