import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import 'dart:async';

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
    _startSessionTimer();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _cleanupListeners();
    _stopHeartbeat();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _socketService = SocketService();
    _apiService = ApiService();
  }

  void _setupSocketListeners() {
    _messageSubscription = _socketService.messageStream.listen(_handleNewMessage);
    _errorSubscription = _socketService.errorStream.listen(_handleError);
  }

  void _cleanupListeners() {
    _messageSubscription.cancel();
    _errorSubscription.cancel();
  }

  void _handleNewMessage(dynamic message) {
    if (!mounted) return;

    setState(() {
      _messages.add({
        'id': message.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'content': message.content ?? '',
        'senderId': message.senderId ?? '',
        'timestamp': message.timestamp ?? DateTime.now(),
        'isFromCurrentUser': false, // This should be determined by actual user comparison
      });
    });
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
      // Add message to UI immediately
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'senderId': 'current_user', // Replace with actual user ID
          'timestamp': DateTime.now(),
          'isFromCurrentUser': true,
        });
      });

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      final isFromCurrentUser = message['isFromCurrentUser'] as bool;
                      
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