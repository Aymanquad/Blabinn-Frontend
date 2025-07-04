import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../core/config.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/user.dart';

enum SocketEvent {
  connect,
  disconnect,
  message,
  typing,
  stopTyping,
  userOnline,
  userOffline,
  messageRead,
  newChat,
  chatUpdated,
  userJoined,
  userLeft,
  error,
  matchFound,
  matchAccepted,
  matchRejected,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  String? _authToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = AppConfig.wsMaxReconnectAttempts;
  final Duration _reconnectDelay = AppConfig.wsReconnectDelay;
  Timer? _heartbeatTimer;

  // Stream controllers for different events
  final StreamController<SocketEvent> _eventController = StreamController<SocketEvent>.broadcast();
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();
  final StreamController<Chat> _chatController = StreamController<Chat>.broadcast();
  final StreamController<User> _userController = StreamController<User>.broadcast();
  final StreamController<String> _typingController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _matchController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  Stream<SocketEvent> get eventStream => _eventController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Chat> get chatStream => _chatController.stream;
  Stream<User> get userStream => _userController.stream;
  Stream<String> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get matchStream => _matchController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Initialize socket connection
  Future<void> connect(String authToken) async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    _eventController.add(SocketEvent.connect);

    try {
      _authToken = authToken;
      final wsUrl = '${AppConfig.wsBaseUrl}?token=$authToken';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _startPingTimer();
      _startHeartbeat();
      _eventController.add(SocketEvent.connect);

      print('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      _handleError(e);
    }
  }

  // Disconnect from socket
  Future<void> disconnect() async {
    _stopPingTimer();
    _stopReconnectTimer();
    _stopHeartbeat();
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
    _isConnecting = false;
    _eventController.add(SocketEvent.disconnect);
    print('WebSocket disconnected');
  }

  // Listen to incoming messages
  void _listenToMessages() {
    _channel?.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          _handleIncomingMessage(message);
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        _handleConnectionError();
      },
      onDone: () {
        print('WebSocket connection closed');
        _handleConnectionError();
      },
    );
  }

  // Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      final event = message['event'] as String;
      final eventData = message['data'];

      switch (event) {
        case 'message':
          _handleIncomingMessage(eventData);
          break;
        case 'typing':
          _handleTypingEvent(eventData);
          break;
        case 'stop_typing':
          _handleStopTypingEvent(eventData);
          break;
        case 'user_online':
          _handleUserOnlineEvent(eventData);
          break;
        case 'user_offline':
          _handleUserOfflineEvent(eventData);
          break;
        case 'message_read':
          _handleMessageReadEvent(eventData);
          break;
        case 'new_chat':
          _handleNewChatEvent(eventData);
          break;
        case 'chat_updated':
          _handleChatUpdatedEvent(eventData);
          break;
        case 'user_joined':
          _handleUserJoinedEvent(eventData);
          break;
        case 'user_left':
          _handleUserLeftEvent(eventData);
          break;
        case 'pong':
          // Handle ping-pong for connection health
          break;
        case 'error':
          _handleServerError(eventData);
          break;
        case 'match_found':
          _handleMatchFoundEvent(eventData);
          break;
        case 'match_accepted':
          _handleMatchAcceptedEvent(eventData);
          break;
        case 'match_rejected':
          _handleMatchRejectedEvent(eventData);
          break;
        default:
          print('Unknown socket event: $event');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle incoming message
  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data);
      _messageController.add(message);
      _eventController.add(SocketEvent.message);
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle typing event
  void _handleTypingEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.typing);
  }

  // Handle stop typing event
  void _handleStopTypingEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.stopTyping);
  }

  // Handle user online event
  void _handleUserOnlineEvent(Map<String, dynamic> data) {
    try {
      final user = User.fromJson(data['user']);
      _userController.add(user);
      _eventController.add(SocketEvent.userOnline);
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle user offline event
  void _handleUserOfflineEvent(Map<String, dynamic> data) {
    try {
      final user = User.fromJson(data['user']);
      _userController.add(user);
      _eventController.add(SocketEvent.userOffline);
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle message read event
  void _handleMessageReadEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.messageRead);
  }

  // Handle new chat event
  void _handleNewChatEvent(Map<String, dynamic> data) {
    try {
      final chat = Chat.fromJson(data['chat']);
      _chatController.add(chat);
      _eventController.add(SocketEvent.newChat);
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle chat updated event
  void _handleChatUpdatedEvent(Map<String, dynamic> data) {
    try {
      final chat = Chat.fromJson(data['chat']);
      _chatController.add(chat);
      _eventController.add(SocketEvent.chatUpdated);
    } catch (e) {
      _handleError(e);
    }
  }

  // Handle user joined event
  void _handleUserJoinedEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.userJoined);
  }

  // Handle user left event
  void _handleUserLeftEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.userLeft);
  }

  // Handle server error
  void _handleServerError(Map<String, dynamic> data) {
    final error = data['message'] ?? 'Unknown server error';
    _errorController.add(error);
    _eventController.add(SocketEvent.error);
  }

  // Handle connection error
  void _handleError(dynamic error) {
    _isConnected = false;
    _isConnecting = false;
    
    final errorMessage = error.toString();
    _errorController.add(errorMessage);
    _eventController.add(SocketEvent.error);
    
    _attemptReconnect();
  }

  // Handle disconnect
  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _eventController.add(SocketEvent.disconnect);
    
    _attemptReconnect();
  }

  // Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _errorController.add('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && !_isConnecting) {
        // Attempt to reconnect - this would need the auth token
        // For now, just log the attempt
        print('Attempting to reconnect... ($_reconnectAttempts/$_maxReconnectAttempts)');
      }
    });
  }

  // Start ping timer for connection health
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendToSocket({
          'event': 'ping',
          'data': {
            'timestamp': DateTime.now().toIso8601String(),
          },
        });
      }
    });
  }

  // Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Send message through socket
  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text}) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'event': 'message',
      'data': {
        'chatId': chatId,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _sendToSocket(message);
  }

  // Send typing indicator
  Future<void> sendTyping(String chatId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'typing',
      'data': {
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _sendToSocket(message);
  }

  // Send stop typing indicator
  Future<void> sendStopTyping(String chatId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'stop_typing',
      'data': {
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _sendToSocket(message);
  }

  // Join chat room
  Future<void> joinChat(String chatId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'join_chat',
      'data': {
        'chatId': chatId,
      },
    };

    _sendToSocket(message);
  }

  // Leave chat room
  Future<void> leaveChat(String chatId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'leave_chat',
      'data': {
        'chatId': chatId,
      },
    };

    _sendToSocket(message);
  }

  // Start random connection
  Future<void> startRandomConnection({
    String? country,
    String? language,
    List<String>? interests,
  }) async {
    if (!_isConnected) return;

    final message = {
      'event': 'start_random_connection',
      'data': {
        if (country != null) 'country': country,
        if (language != null) 'language': language,
        if (interests != null) 'interests': interests,
      },
    };

    _sendToSocket(message);
  }

  // Stop random connection
  Future<void> stopRandomConnection() async {
    if (!_isConnected) return;

    final message = {
      'event': 'stop_random_connection',
      'data': {},
    };

    _sendToSocket(message);
  }

  // Send call request
  Future<void> sendCallRequest(String chatId, String callType) async {
    if (!_isConnected) return;

    final message = {
      'event': 'call_request',
      'data': {
        'chatId': chatId,
        'callType': callType, // 'audio' or 'video'
      },
    };

    _sendToSocket(message);
  }

  // Accept call
  Future<void> acceptCall(String callId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'call_accepted',
      'data': {
        'callId': callId,
      },
    };

    _sendToSocket(message);
  }

  // Reject call
  Future<void> rejectCall(String callId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'call_rejected',
      'data': {
        'callId': callId,
      },
    };

    _sendToSocket(message);
  }

  // End call
  Future<void> endCall(String callId) async {
    if (!_isConnected) return;

    final message = {
      'event': 'call_ended',
      'data': {
        'callId': callId,
      },
    };

    _sendToSocket(message);
  }

  // Send to socket
  void _sendToSocket(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
        _handleConnectionError();
      }
    }
  }

  // Handle match found event
  void _handleMatchFoundEvent(Map<String, dynamic> data) {
    _matchController.add(data);
    _eventController.add(SocketEvent.matchFound);
  }

  // Handle match accepted event
  void _handleMatchAcceptedEvent(Map<String, dynamic> data) {
    _matchController.add(data);
    _eventController.add(SocketEvent.matchAccepted);
  }

  // Handle match rejected event
  void _handleMatchRejectedEvent(Map<String, dynamic> data) {
    _matchController.add(data);
    _eventController.add(SocketEvent.matchRejected);
  }

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendToSocket({
        'event': 'ping',
        'data': {
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _eventController.close();
    _messageController.close();
    _chatController.close();
    _userController.close();
    _typingController.close();
    _matchController.close();
    _errorController.close();
  }
} 