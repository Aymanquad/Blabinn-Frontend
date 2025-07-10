import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;

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
  final List<Map<String, dynamic>> _messages = [];
  late SocketService _socketService;
  late ApiService _apiService;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _errorSubscription;
  bool _isSessionActive = true;
  Timer? _heartbeatTimer;
  int _timeRemaining = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupSocketListeners();
    _joinChatRoom();
    _startSessionTimer();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _cleanupListeners();
    _stopHeartbeat();
    _leaveChatRoom();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _socketService = SocketService();
    _apiService = ApiService();
  }

  void _setupSocketListeners() {
    _messageSubscription =
        _socketService.messageStream.listen(_handleNewMessage);
    _errorSubscription = _socketService.errorStream.listen(_handleError);
  }

  void _joinChatRoom() {
    try {
      _socketService.joinChat(widget.chatRoomId);
      print('🔌 [RANDOM CHAT DEBUG] Joined chat room: ${widget.chatRoomId}');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Failed to join chat room: $e');
    }
  }

  void _leaveChatRoom() {
    try {
      _socketService.leaveChat(widget.chatRoomId);
      print('🚪 [RANDOM CHAT DEBUG] Left chat room: ${widget.chatRoomId}');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Failed to leave chat room: $e');
    }
  }

  void _cleanupListeners() {
    _messageSubscription.cancel();
    _errorSubscription.cancel();
  }

  void _handleNewMessage(dynamic message) async {
    if (!mounted) return;

    final messageId =
        message.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final messageContent = message.content ?? '';
    final messageSenderId = message.senderId ?? '';

    // Get current user ID from Firebase Auth
    String? currentUserId;
    try {
      final user = FirebaseAuth.FirebaseAuth.instance.currentUser;
      currentUserId = user?.uid;
      print('🔍 [RANDOM CHAT DEBUG] Current user ID: $currentUserId');
      print('🔍 [RANDOM CHAT DEBUG] Message sender ID: $messageSenderId');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Error getting current user: $e');
    }

    // Check if this is a message from the current user
    final isFromCurrentUser =
        currentUserId != null && messageSenderId == currentUserId;

    print('🔍 [RANDOM CHAT DEBUG] Is from current user: $isFromCurrentUser');

    // Check if we have a temporary message with the same content from current user
    final tempMessageIndex = _messages.indexWhere((msg) =>
        msg['content'] == messageContent &&
        msg['isFromCurrentUser'] == true &&
        msg['id'].toString().startsWith('temp_'));

    if (tempMessageIndex != -1 && isFromCurrentUser) {
      // Replace temporary message with real message
      print(
          '🔄 [RANDOM CHAT DEBUG] Replacing temp message with real message: $messageId');
      setState(() {
        _messages[tempMessageIndex] = {
          'id': messageId,
          'content': messageContent,
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
        print(
            '⏭️ [RANDOM CHAT DEBUG] Message already in UI, skipping: $messageId');
        return;
      }

      // Add new message
      setState(() {
        _messages.add({
          'id': messageId,
          'content': messageContent,
          'senderId': messageSenderId,
          'timestamp': message.timestamp ?? DateTime.now(),
          'isFromCurrentUser': isFromCurrentUser,
        });
      });

      print(
          '✅ [RANDOM CHAT DEBUG] Added new message to UI: $messageContent (from current user: $isFromCurrentUser)');
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
      // Add message to UI immediately (optimistic update)
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.add({
          'id': tempMessageId,
          'content': content,
          'senderId':
              'current_user', // Will be updated when we get the real message
          'timestamp': DateTime.now(),
          'isFromCurrentUser': true,
        });
      });

      print('📤 [RANDOM CHAT DEBUG] Added optimistic message to UI: $content');

      _messageController.clear();

      // Send via socket
      await _socketService.sendMessage(
        widget.chatRoomId,
        content,
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

  Future<void> _endSession(String reason) async {
    if (!_isSessionActive) return;

    setState(() {
      _isSessionActive = false;
    });

    try {
      // End session via API
      // await _apiService.endRandomChatSession(widget.sessionId, reason);

      _stopHeartbeat();

      // Show end session dialog
      _showSessionEndDialog(reason);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ending session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSessionEndDialog(String reason) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Chat'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _endSession('user_ended'),
          ),
        ],
      ),
      body: Column(
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start chatting!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Say hello to your random chat partner',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message['content'] as String,
                            style: TextStyle(
                              color: isFromCurrentUser
                                  ? Colors.white
                                  : Colors.black87,
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
                color: Colors.white,
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
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
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
    );
  }
}
