import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/chat_moderation_service.dart';
import '../widgets/consistent_app_bar.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../utils/html_decoder.dart';

class RandomChatScreen extends StatefulWidget {
  final String sessionId;
  final String chatRoomId;

  const RandomChatScreen({
    super.key,
    required this.sessionId,
    required this.chatRoomId,
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
  late StreamSubscription _messageSubscription;
  late StreamSubscription _errorSubscription;
  late StreamSubscription _eventSubscription;
  bool _isSessionActive = true;
  bool _hasShownEndDialog = false; // Prevent multiple dialogs
  bool _isDisposing = false; // Prevent multiple dispose calls
  Timer? _heartbeatTimer;
  int _timeRemaining = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _validateSession();
    _setupSocketListeners();
    _joinChatRoom();
    _startSessionTimer();
    _startHeartbeat();
    _startSessionTimeout();
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
    showDialog(
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
              Navigator.pop(context); // Go back to connect screen
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

    final messageId =
        message.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final messageContent =
        HtmlDecoder.decodeHtmlEntities(message.content ?? '');
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
    final isFromCurrentUser =
        currentUserId != null && messageSenderId == currentUserId;

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
      setState(() {
        _messages.add({
          'id': messageId,
          'content': moderatedContent,
          'senderId': messageSenderId,
          'timestamp': message.timestamp ?? DateTime.now(),
          'isFromCurrentUser': isFromCurrentUser,
        });
      });

      _scrollToBottom();

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

  void _startSessionTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isSessionActive) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        timer.cancel();
        _endSession('timeout');
      }
    });
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
    if (content.isEmpty || !_isSessionActive) return;

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
        title = 'Time\'s Up!';
        message = 'Your 5-minute chat session has ended.';
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

    showDialog(
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
              Navigator.pop(context); // Go back to connect screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showExitWarningDialog() {
    showDialog(
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

  // Note: _forceCleanup method removed (unused)

  void _startSessionTimeout() {
    // Remove the aggressive timeout that was causing false errors
    // The session should only end when explicitly ended by users or server
    print(
        '⏰ [RANDOM CHAT DEBUG] Session timeout disabled - relying on explicit session events');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = true; // Always dark mode

    return WillPopScope(
      onWillPop: () async {
        // Always use the unified end session method
        _showExitWarningDialog();
        return false; // Prevent default back button behavior
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
                  Colors.black.withOpacity(0.35),
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
            Container(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _timeRemaining <= 30 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTime(_timeRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/violettoblack_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
            Column(
          children: [
            // Session info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.primary.withOpacity(0.1),
              child: Text(
                'Random chat session active • ${_formatTime(_timeRemaining)} remaining',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Messages list
            Expanded(
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
                            'Say hello to your random chat partner',
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
                        final message = _messages[index];
                        final isFromCurrentUser =
                            message['isFromCurrentUser'] as bool;

                        return Align(
                          alignment: isFromCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isFromCurrentUser
                                  ? AppColors.primary
                                  : AppColors.receivedMessage,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              HtmlDecoder.decodeHtmlEntities(
                                  message['content'] as String),
                              style: TextStyle(
                                color: isFromCurrentUser
                                    ? Colors.white
                                    : AppColors.text,
                              ),
                            ),
                          ),
                        );
                      },
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
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
                              suffixIcon: _messageController.text.length > 900
                                  ? Icon(
                                      Icons.warning,
                                      color:
                                          _messageController.text.length >= 1000
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
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          if (_messageController.text.length > 900)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 16),
                              child: Text(
                                '${_messageController.text.length}/1000',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _messageController.text.length >= 1000
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
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
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
}
