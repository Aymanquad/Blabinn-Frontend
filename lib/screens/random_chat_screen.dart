import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../services/socket_service.dart';
import '../services/socket/socket_types.dart';
import '../services/api_service.dart';
import '../services/chat_moderation_service.dart';
import '../services/global_matching_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../utils/html_decoder.dart';
import '../models/message.dart';

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
  late StreamSubscription _matchSubscription;
  late StreamSubscription _globalMatchingSubscription;
  bool _isSessionActive = true;
  bool _hasShownEndDialog = false; // Prevent multiple dialogs
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
    _cleanupListeners();
    _stopHeartbeat();
    _leaveChatRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _socketService = SocketService();
    _apiService = ApiService();
  }

  void _setupSocketListeners() {
    _messageSubscription = _socketService.messageStream.listen(
      (messageData) {
        if (mounted) {
          _handleIncomingMessage(messageData);
        }
      },
      onError: (error) {
        print('❌ [RANDOM CHAT DEBUG] Message stream error: $error');
        if (mounted) {
          _showSessionErrorDialog('Connection error. Please try again.');
        }
      },
    );

    _errorSubscription = _socketService.errorStream.listen(
      (error) {
        print('❌ [RANDOM CHAT DEBUG] Socket error: $error');
        if (mounted) {
          _showSessionErrorDialog('Connection lost. Please try again.');
        }
      },
    );

    // Listen for session ended events
    _eventSubscription = _socketService.eventStream.listen(
      (event) {
        if (mounted && _isSessionActive) {
          if (event == SocketEvent.randomChatSessionEnded || event == SocketEvent.userLeft) {
            _handleOtherUserExit();
          }
        }
      },
      onError: (error) {
        print('❌ [RANDOM CHAT DEBUG] Event stream error: $error');
      },
    );

    // Listen for match events (when partner leaves)
    _matchSubscription = _socketService.matchStream.listen(
      (data) {
        if (mounted && _isSessionActive) {
          if (data['event'] == 'partner_left' || data['event'] == 'session_ended') {
            _handleOtherUserExit();
          }
        }
      },
      onError: (error) {
        print('❌ [RANDOM CHAT DEBUG] Match stream error: $error');
      },
    );

    // Listen for global matching service events (partner left)
    _globalMatchingSubscription = GlobalMatchingService().messageStream.listen(
      (message) {
        if (mounted && _isSessionActive) {
          if (message != null && message.contains('Partner left')) {
            _handleOtherUserExit();
          }
        }
      },
      onError: (error) {
        print('❌ [RANDOM CHAT DEBUG] Global matching stream error: $error');
      },
    );
  }

  Future<void> _joinChatRoom() async {
    try {
      await _socketService.joinChat(widget.chatRoomId);
      print('✅ [RANDOM CHAT DEBUG] Joined chat room: ${widget.chatRoomId}');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Failed to join chat room: $e');
      if (mounted) {
        _showSessionErrorDialog('Failed to join chat room. Please try again.');
      }
    }
  }

  void _leaveChatRoom() {
    try {
      _socketService.leaveChat(widget.chatRoomId);
      print('✅ [RANDOM CHAT DEBUG] Left chat room: ${widget.chatRoomId}');
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Error leaving chat room: $e');
    }
  }

  void _startSessionTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isSessionActive) {
        setState(() {
          _timeRemaining--;
        });

        if (_timeRemaining <= 0) {
          timer.cancel();
          _endSession();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _isSessionActive) {
        // Heartbeat functionality removed - not needed for basic random chat
        print('💓 [RANDOM CHAT DEBUG] Heartbeat tick');
      } else {
        timer.cancel();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  void _startSessionTimeout() {
    Timer(const Duration(minutes: 5), () {
      if (mounted && _isSessionActive) {
        _endSession();
      }
    });
  }

  void _endSession() {
    if (!_isSessionActive || _hasShownEndDialog) return;

    setState(() {
      _isSessionActive = false;
      _hasShownEndDialog = true;
    });

    _showSessionEndDialog();
  }

  void _exitSession() {
    // Show confirmation dialog before exiting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text('Exit Chat'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit? This will end the chat for both users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _forceExitSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _forceExitSession() {
    // Exit both users from the session
    _socketService.leaveChat(widget.chatRoomId);
    _socketService.disconnect();
    
    // Navigate back to connect screen
    Navigator.pop(context);
  }

  void _handleOtherUserExit() {
    // When other user exits, show dialog and exit this user too
    if (mounted && _isSessionActive) {
      setState(() {
        _isSessionActive = false;
      });
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Partner Left'),
            ],
          ),
          content: const Text(
            'Your chat partner has left the conversation. You will be returned to the connect screen.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _forceExitSession(); // Exit session
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSessionEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Ended'),
          ],
        ),
        content: const Text(
          'Your random chat session has ended. You can start a new session anytime!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _exitSession(); // Exit session properly
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleIncomingMessage(Message message) {
    final messageContent = message.content ?? '';
    final senderId = message.senderId ?? '';
    final timestamp = message.timestamp ?? DateTime.now();

    if (messageContent.isNotEmpty && senderId.isNotEmpty) {
      // Check if this message is already in the list to prevent duplicates
      final messageId = '${senderId}_${timestamp.millisecondsSinceEpoch}';
      final isDuplicate = _messages.any((msg) => 
        msg['senderId'] == senderId && 
        msg['timestamp'] == timestamp.toIso8601String()
      );

      if (!isDuplicate) {
        setState(() {
          _messages.add({
            'message': messageContent,
            'senderId': senderId,
            'timestamp': timestamp.toIso8601String(),
            'isMe': senderId == FirebaseAuth.FirebaseAuth.instance.currentUser?.uid,
          });
        });

        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_isSessionActive) return;

    // Check message moderation
    final isAppropriate = !_moderationService.containsInappropriateContent(message);
    if (!isAppropriate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message contains inappropriate content. Please revise.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _socketService.sendMessage(widget.chatRoomId, message);
      _messageController.clear();
    } catch (e) {
      print('❌ [RANDOM CHAT DEBUG] Failed to send message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cleanupListeners() {
    _messageSubscription.cancel();
    _errorSubscription.cancel();
    _eventSubscription.cancel();
    _matchSubscription.cancel();
    _globalMatchingSubscription.cancel();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when user tries to go back
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Exit Chat'),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit? This will end the chat for both users.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close dialog
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _forceExitSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return false; // Prevent back navigation
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2D1B69),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D1B69),
          elevation: 0,
          automaticallyImplyLeading: false, // Disable back button
          title: Row(
            children: [
              const Text(
                'Random Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(_timeRemaining),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _exitSession,
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D1B69),
                Color(0xFF1A0B3D),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Start chatting!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your messages will appear here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final messageText = message['message'] as String;
    final timestamp = DateTime.tryParse(message['timestamp'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                  ? const Color(0xFF8B5CF6)
                  : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messageText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(
              Icons.send,
              color: Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
