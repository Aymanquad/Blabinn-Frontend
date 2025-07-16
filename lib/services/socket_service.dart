import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
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
  randomConnectionStarted,
  randomChatEvent,
  randomChatTimeout,
  randomChatSessionEnded,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _authToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _intentionalDisconnect =
      false; // Add flag to track intentional disconnects
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = AppConfig.wsMaxReconnectAttempts;
  final Duration _reconnectDelay = AppConfig.wsReconnectDelay;
  Timer? _heartbeatTimer;
  DateTime? _connectionTime;

  // Message deduplication
  final Set<String> _processedMessageIds = {};

  // Stream controllers for different events
  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Chat> _chatController =
      StreamController<Chat>.broadcast();
  final StreamController<User> _userController =
      StreamController<User>.broadcast();
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _matchController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

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
    _intentionalDisconnect = false; // Reset flag for new connection
    _eventController.add(SocketEvent.connect);

    try {
      _authToken = authToken;

      print('🔍 [SOCKET DEBUG] Attempting to connect to Socket.IO server');
      print('   🌐 URL: ${AppConfig.wsBaseUrl}');
      print('   🔑 Token length: ${authToken.length}');

      _socket = IO.io(
        AppConfig.wsBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': _authToken})
            .setTimeout(5000)  // Reduced from 20000 to 5000
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ [SOCKET DEBUG] Socket.IO connected successfully');
        print('   🔌 Setting _isConnected = true');
        _isConnected = true;
        _isConnecting = false;
        _connectionTime = DateTime.now(); // Track connection time

        // Log if this was a reconnection before resetting
        if (_reconnectAttempts > 0) {
          print(
              '🔄 [SOCKET DEBUG] Successfully reconnected after $_reconnectAttempts attempts');
        }

        _reconnectAttempts =
            0; // Reset reconnection attempts on successful connection
        _stopReconnectTimer(); // Stop any pending reconnection timers
        _startPingTimer();
        _startHeartbeat();
        _eventController.add(SocketEvent.connect);

        print('📤 [SOCKET DEBUG] About to send join event automatically');
        // Add small delay to ensure connection is stable before sending join event
        Timer(const Duration(milliseconds: 100), () {
          if (_isConnected) {
            _sendJoinEvent();
          }
        });
      });

      _socket!.onDisconnect((reason) {
        print('🔌 [SOCKET DEBUG] Socket.IO disconnected');
        print('   📊 Disconnect reason: $reason');
        print('   📊 Socket ID: ${_socket?.id}');
        print(
            '   📊 Time connected: ${DateTime.now().difference(_connectionTime ?? DateTime.now()).inSeconds}s');
        _handleDisconnect();
      });

      _socket!.onError((error) {
        print('❌ [SOCKET DEBUG] Socket.IO error: $error');
        _handleError(error);
      });

      // Handle all events
      _socket!.onAny((event, data) {
        print('🔍 [SOCKET DEBUG] Received event: $event');
        print('   📦 Data: $data');
        _handleSocketEvent(event, data);
      });

      _socket!.connect();
    } catch (e) {
      print('❌ [SOCKET DEBUG] Connection failed: $e');
      _isConnecting = false;
      _handleError(e);
    }
  }

  // Disconnect from socket
  Future<void> disconnect() async {
    _intentionalDisconnect = true; // Mark as intentional disconnect
    _stopPingTimer();
    _stopReconnectTimer();
    _stopHeartbeat();

    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _eventController.add(SocketEvent.disconnect);
    print('🔌 [SOCKET DEBUG] Socket.IO intentionally disconnected');
  }

  // Note: No longer needed with Socket.IO - events are handled directly

  // Handle Socket.IO events
  void _handleSocketEvent(String event, dynamic data) {
    try {
      print('🔍 [SOCKET DEBUG] Processing event: $event');
      print('   📦 Data type: ${data.runtimeType}');
      print('   📦 Data value: $data');

      // Add null safety check
      if (data != null && data is! Map<String, dynamic> && data is! List) {
        print(
            '⚠️ [SOCKET DEBUG] Unexpected data type for event $event: ${data.runtimeType}');
        print('   📦 Converting to safe format...');
        // Convert to safe format if possible
        if (data is String) {
          data = {'message': data};
        } else {
          data = {'data': data.toString()};
        }
      }

      switch (event) {
        case 'message':
          _handleIncomingMessage(data);
          break;
        case 'typing':
          _handleTypingEvent(data);
          break;
        case 'stop_typing':
          _handleStopTypingEvent(data);
          break;
        case 'user_online':
          _handleUserOnlineEvent(data);
          break;
        case 'user_offline':
          _handleUserOfflineEvent(data);
          break;
        case 'message_read':
          _handleMessageReadEvent(data);
          break;
        case 'new_chat':
          _handleNewChatEvent(data);
          break;
        case 'chat_updated':
          _handleChatUpdatedEvent(data);
          break;
        case 'user_joined':
          _handleUserJoinedEvent(data);
          break;
        case 'user_left':
          _handleUserLeftEvent(data);
          break;
        case 'pong':
          // Handle ping-pong for connection health
          break;
        case 'error':
          _handleServerError(data);
          break;
        case 'match_found':
          _handleMatchFoundEvent(data);
          break;
        case 'match_accepted':
          _handleMatchAcceptedEvent(data);
          break;
        case 'match_rejected':
          _handleMatchRejectedEvent(data);
          break;
        case 'random_connection_started':
          _handleRandomConnectionStartedEvent(data);
          break;
        case 'random_chat_event':
          _handleRandomChatEvent(data);
          break;
        case 'random_chat_timeout':
          _handleRandomChatTimeoutEvent(data);
          break;
        case 'joined':
          _handleJoinedEvent(data);
          break;
        case 'new_message':
          _handleNewMessageEvent(data);
          break;
        case 'message_sent':
          _handleMessageSentEvent(data);
          break;
        case 'chat_joined':
          _handleChatJoinedEvent(data);
          break;
        case 'random_chat_session_ended':
          _handleRandomChatSessionEndedEvent(data);
          break;
        case 'random_chat_event':
          _handleRandomChatEventReceived(data);
          break;
        default:
          print('Unknown socket event: $event');
      }
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error processing event $event: $e');
      print('   📦 Data that caused error: $data');
      print('   🔍 Stack trace: ${StackTrace.current}');
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
  void _handleUserOnlineEvent(dynamic data) {
    print('👥 [SOCKET DEBUG] User online event received');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] User online data is null');
        return;
      }

      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        // Check if data has 'user' nested object or direct user data
        if (data.containsKey('user') && data['user'] != null) {
          userData = data['user'];
        } else {
          // Data is direct user data format
          userData = data;
        }
      } else {
        print(
            '❌ [SOCKET DEBUG] Invalid user online data type: ${data.runtimeType}');
        return;
      }

      print('   👤 Processing user data: $userData');
      final user = User.fromJson(userData);
      _userController.add(user);
      _eventController.add(SocketEvent.userOnline);
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling user online event: $e');
      print('   📦 Data that caused error: $data');
      // Don't call _handleError as this will cause reconnection loop
    }
  }

  // Handle user offline event
  void _handleUserOfflineEvent(dynamic data) {
    print('👥 [SOCKET DEBUG] User offline event received');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] User offline data is null');
        return;
      }

      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        // Check if data has 'user' nested object or direct user data
        if (data.containsKey('user') && data['user'] != null) {
          userData = data['user'];
        } else {
          // Data is direct user data format
          userData = data;
        }
      } else {
        print(
            '❌ [SOCKET DEBUG] Invalid user offline data type: ${data.runtimeType}');
        return;
      }

      print('   👤 Processing user data: $userData');
      final user = User.fromJson(userData);
      _userController.add(user);
      _eventController.add(SocketEvent.userOffline);
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling user offline event: $e');
      print('   📦 Data that caused error: $data');
      // Don't call _handleError as this will cause reconnection loop
    }
  }

  // Handle message read event
  void _handleMessageReadEvent(Map<String, dynamic> data) {
    _eventController.add(SocketEvent.messageRead);
  }

  // Handle new chat event
  void _handleNewChatEvent(dynamic data) {
    print('💬 [SOCKET DEBUG] New chat event received');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] New chat data is null');
        return;
      }

      if (data is! Map<String, dynamic>) {
        print(
            '❌ [SOCKET DEBUG] Invalid new chat data type: ${data.runtimeType}');
        return;
      }

      final chatData = data['chat'];
      if (chatData == null) {
        print('❌ [SOCKET DEBUG] Chat data is null in new chat event');
        return;
      }

      final chat = Chat.fromJson(chatData);
      _chatController.add(chat);
      _eventController.add(SocketEvent.newChat);
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling new chat event: $e');
      print('   📦 Data that caused error: $data');
      // Don't call _handleError as this will cause reconnection loop
    }
  }

  // Handle chat updated event
  void _handleChatUpdatedEvent(dynamic data) {
    print('💬 [SOCKET DEBUG] Chat updated event received');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] Chat updated data is null');
        return;
      }

      if (data is! Map<String, dynamic>) {
        print(
            '❌ [SOCKET DEBUG] Invalid chat updated data type: ${data.runtimeType}');
        return;
      }

      final chatData = data['chat'];
      if (chatData == null) {
        print('❌ [SOCKET DEBUG] Chat data is null in chat updated event');
        return;
      }

      final chat = Chat.fromJson(chatData);
      _chatController.add(chat);
      _eventController.add(SocketEvent.chatUpdated);
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling chat updated event: $e');
      print('   📦 Data that caused error: $data');
      // Don't call _handleError as this will cause reconnection loop
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
  void _handleServerError(dynamic data) {
    print('🔴 [SOCKET DEBUG] Server error received');
    print('   📦 Error data type: ${data.runtimeType}');
    print('   📦 Error data: $data');

    String error;
    Map<String, dynamic>? errorData;

    if (data == null) {
      error = 'Unknown server error (null data)';
    } else if (data is Map<String, dynamic>) {
      errorData = data;
      error = data['message'] ?? 'Unknown server error';
    } else if (data is String) {
      error = data;
    } else {
      error = 'Server error: ${data.toString()}';
    }

    print('   📝 Final error message: $error');

    // Add structured error data if available
    if (errorData != null) {
      _errorController.add(
          '$error|${errorData['code'] ?? ''}|${errorData['sessionId'] ?? ''}|${errorData['chatRoomId'] ?? ''}');
    } else {
      _errorController.add(error);
    }
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

  // Handle connection error specifically
  void _handleConnectionError() {
    _isConnected = false;
    _isConnecting = false;

    _errorController.add('Connection error occurred');
    _eventController.add(SocketEvent.error);

    _attemptReconnect();
  }

  // Handle disconnect
  void _handleDisconnect() {
    print('🔌 [SOCKET DEBUG] _handleDisconnect called');
    print('   📊 Previous _isConnected: $_isConnected');
    print('   📊 Previous _isConnecting: $_isConnecting');
    print('   📊 _intentionalDisconnect: $_intentionalDisconnect');
    print('   📊 Socket state: ${_socket?.connected}');

    _isConnected = false;
    _isConnecting = false;
    _eventController.add(SocketEvent.disconnect);

    // Only attempt reconnection if disconnect was not intentional
    if (!_intentionalDisconnect) {
      print(
          '🔌 [SOCKET DEBUG] Unexpected disconnect detected, attempting reconnection');
      _attemptReconnect();
    } else {
      print('🔌 [SOCKET DEBUG] Intentional disconnect, no reconnection needed');
      // Reset intentional disconnect flag for next connection
      _intentionalDisconnect = false;
    }
  }

  // Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _errorController.add('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    print(
        '🔄 [SOCKET DEBUG] Attempting to reconnect... ($_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && !_isConnecting && _authToken != null) {
        print(
            '🔄 [SOCKET DEBUG] Executing reconnection attempt $_reconnectAttempts');
        connect(_authToken!).catchError((error) {
          print(
              '❌ [SOCKET DEBUG] Reconnection attempt $_reconnectAttempts failed: $error');
          // If this attempt failed, try again after delay
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _attemptReconnect();
          }
        });
      }
    });
  }

  // Start ping timer for connection health
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      // Reduced from 30 to 60 seconds
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

  // Send message through socket (for random chat)
  Future<void> sendMessage(String chatId, String content,
      {MessageType type = MessageType.text}) async {
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

  // Send message to friend (for friend chat)
  Future<void> sendFriendMessage(String receiverId, String content,
      {MessageType type = MessageType.text}) async {
    print('📤 [SOCKET DEBUG] sendFriendMessage called');
    print('   🎯 Receiver ID: $receiverId');
    print('   💬 Content: $content');
    print('   🔗 Connected: $_isConnected');

    if (!_isConnected) {
      print('❌ [SOCKET DEBUG] Cannot send friend message - not connected');
      throw Exception('WebSocket not connected');
    }

    final message = {
      'receiverId': receiverId,
      'content': content,
      'messageType': type.toString().split('.').last,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 [SOCKET DEBUG] Sending friend message via socket');
    print('   📦 Message data: $message');
    
    // Use the Socket.IO emit method directly for friend messages
    _socket!.emit('message', message);
  }

  // Send image message to friend
  Future<void> sendFriendImageMessage(String receiverId, String imageUrl) async {
    print('📤 [SOCKET DEBUG] sendFriendImageMessage called');
    print('   🎯 Receiver ID: $receiverId');
    print('   🖼️ Image URL: $imageUrl');
    print('   🔗 Connected: $_isConnected');

    if (!_isConnected) {
      print('❌ [SOCKET DEBUG] Cannot send friend image message - not connected');
      throw Exception('WebSocket not connected');
    }

    final message = {
      'receiverId': receiverId,
      'content': 'Image',
      'imageUrl': imageUrl,
      'messageType': 'image',
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 [SOCKET DEBUG] Sending friend image message via socket');
    print('   📦 Message data: $message');
    
    // Use the Socket.IO emit method directly for friend image messages
    _socket!.emit('message', message);
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
    print('🔌 [SOCKET DEBUG] joinChat called with chatId: $chatId');
    print('   🔗 _isConnected: $_isConnected');

    if (!_isConnected) {
      print('❌ [SOCKET DEBUG] Cannot join chat - not connected');
      return;
    }

    final message = {
      'event': 'join_chat',
      'data': {
        'chatId': chatId,
      },
    };

    print('📤 [SOCKET DEBUG] Sending join_chat event');
    print('   📦 Message: $message');
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
    String? genderPreference,
  }) async {
    print('🎯 [SOCKET DEBUG] startRandomConnection called');
    print('   🔌 _isConnected: $_isConnected');
    print('   📡 _socket != null: ${_socket != null}');
    print('   🌍 country: $country');
    print('   🗣️ language: $language');
    print('   💫 interests: $interests');
    print('   👤 genderPreference: $genderPreference');
    
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');
    print('🎯 [INTEREST MATCH DEBUG] USER JOINING RANDOM CHAT QUEUE');
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');
    if (interests != null && interests.isNotEmpty) {
      print('🎯 [INTEREST MATCH DEBUG] User interests: $interests');
      print('🎯 [INTEREST MATCH DEBUG] Total interests: ${interests.length}');
      print('🎯 [INTEREST MATCH DEBUG] Looking for matches with similar interests...');
    } else {
      print('🎯 [INTEREST MATCH DEBUG] User has no interests - will match with anyone');
    }
    if (genderPreference != null && genderPreference != 'any') {
      print('🎯 [GENDER MATCH DEBUG] User gender preference: $genderPreference');
      print('🎯 [GENDER MATCH DEBUG] Looking for matches with $genderPreference gender...');
    } else {
      print('🎯 [GENDER MATCH DEBUG] User has no gender preference - will match with anyone');
    }
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');

    // Check both _isConnected flag AND actual socket state
    final isActuallyConnected = _isConnected && _socket?.connected == true;
    print('   🔗 Actually connected: $isActuallyConnected');

    if (!isActuallyConnected) {
      print('❌ [SOCKET DEBUG] startRandomConnection aborted - not connected');
      print('   🔌 _isConnected: $_isConnected');
      print('   📡 Socket state: ${_socket?.connected}');

      // If socket is connected but flag is false, fix the flag
      if (_socket?.connected == true && !_isConnected) {
        print('🔧 [SOCKET DEBUG] Fixing connection flag mismatch');
        _isConnected = true;
      } else {
        return;
      }
    }

    final message = {
      'event': 'start_random_connection',
      'data': {
        if (country != null) 'country': country,
        if (language != null) 'language': language,
        if (interests != null) 'interests': interests,
        if (genderPreference != null) 'genderPreference': genderPreference,
      },
    };

    print('📤 [SOCKET DEBUG] About to send startRandomConnection event');
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

  // End random chat session
  Future<void> endRandomChatSession(String sessionId, String reason) async {
    print('🚪 [SOCKET DEBUG] endRandomChatSession called');
    print('   📱 Session ID: $sessionId');
    print('   💭 Reason: $reason');
    print('   🔗 Connected: $_isConnected');

    if (!_isConnected) {
      print('❌ [SOCKET DEBUG] Cannot end session - not connected');
      throw Exception('Socket not connected');
    }

    final message = {
      'sessionId': sessionId,
      'reason': reason,
    };

    print('📤 [SOCKET DEBUG] Sending end_random_chat_session event');
    print('   📦 Message data: $message');
    
    // Use the Socket.IO emit method directly
    _socket!.emit('end_random_chat_session', message);
  }

  // Send to socket
  void _sendToSocket(Map<String, dynamic> message) {
    if (_socket != null && _isConnected) {
      try {
        print('📤 [SOCKET DEBUG] Sending event: ${message['event']}');
        print('   📦 Data: ${message['data']}');
        _socket!.emit(message['event'], message['data']);
      } catch (e) {
        print('❌ [SOCKET DEBUG] Error sending message: $e');
        _handleConnectionError();
      }
    }
  }

  // Handle match found event
  void _handleMatchFoundEvent(Map<String, dynamic> data) {
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');
    print('🎯 [INTEREST MATCH DEBUG] MATCH FOUND EVENT RECEIVED!');
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');
    print('   📦 Full data: $data');
    
    // Extract match information
    final matchType = data['matchType'] ?? 'unknown';
    final interestSimilarity = data['interestSimilarity'] ?? 0.0;
    final user1 = data['user1'];
    final user2 = data['user2'];
    final user1Interests = data['user1Interests'] ?? [];
    final user2Interests = data['user2Interests'] ?? [];
    
    print('🎯 [INTEREST MATCH DEBUG] Match Type: $matchType');
    print('🎯 [INTEREST MATCH DEBUG] Interest Similarity: ${(interestSimilarity * 100).toStringAsFixed(1)}%');
    print('🎯 [INTEREST MATCH DEBUG] User 1: ${user1?['userId'] ?? 'Unknown'}');
    print('🎯 [INTEREST MATCH DEBUG] User 1 Interests: $user1Interests');
    print('🎯 [INTEREST MATCH DEBUG] User 2: ${user2?['userId'] ?? 'Unknown'}');
    print('🎯 [INTEREST MATCH DEBUG] User 2 Interests: $user2Interests');
    
    // Show common interests
    if (user1Interests is List && user2Interests is List) {
      final commonInterests = user1Interests.where((interest) => 
        user2Interests.any((otherInterest) => 
          interest.toString().toLowerCase() == otherInterest.toString().toLowerCase()
        )
      ).toList();
      
      if (commonInterests.isNotEmpty) {
        print('🎯 [INTEREST MATCH DEBUG] Common Interests: $commonInterests');
      } else {
        print('🎯 [INTEREST MATCH DEBUG] No common interests found');
      }
    }
    
    if (matchType == 'interest-based') {
      print('🎯 [INTEREST MATCH DEBUG] ⭐ SUCCESS: Users matched based on shared interests!');
    } else if (matchType == 'fallback') {
      print('🎯 [INTEREST MATCH DEBUG] ⏰ FALLBACK: Users matched after preference window expired');
    }
    
    print('🎯 [INTEREST MATCH DEBUG] ===============================================');
    
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

  // Handle random connection started event
  void _handleRandomConnectionStartedEvent(dynamic data) {
    print('🚀 [SOCKET DEBUG] Random connection started event received');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    if (data == null) {
      print('❌ [SOCKET DEBUG] Random connection started data is null');
      _errorController.add('Random connection started with null data');
      return;
    }

    Map<String, dynamic> eventData;
    if (data is Map<String, dynamic>) {
      eventData = data;
    } else {
      eventData = {'status': 'started', 'data': data.toString()};
    }

    _matchController.add(eventData);
    _eventController.add(SocketEvent.randomConnectionStarted);
  }

  // Handle random chat event
  void _handleRandomChatEvent(dynamic data) {
    print('🎉 [SOCKET DEBUG] Random chat event received!');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Raw data: $data');
    
    // Extract and display match analytics if available
    if (data is Map<String, dynamic>) {
      final matchType = data['matchType'];
      final interestSimilarity = data['interestSimilarity'];
      final user1Interests = data['user1Interests'];
      final user2Interests = data['user2Interests'];
      
      if (matchType != null) {
        print('🎯 [INTEREST MATCH DEBUG] Chat started with match type: $matchType');
        if (interestSimilarity != null) {
          print('🎯 [INTEREST MATCH DEBUG] Interest similarity: ${(interestSimilarity * 100).toStringAsFixed(1)}%');
        }
        if (user1Interests != null && user2Interests != null) {
          print('🎯 [INTEREST MATCH DEBUG] User interests: $user1Interests vs $user2Interests');
        }
      }
    }

    // Null safety check
    if (data == null) {
      print('❌ [SOCKET DEBUG] Random chat event data is null');
      _errorController.add('Random chat event received null data');
      return;
    }

    Map<String, dynamic> eventData;
    if (data is Map<String, dynamic>) {
      eventData = data;
    } else if (data is String) {
      // Try to parse as JSON if it's a string
      try {
        eventData = {'message': data};
      } catch (e) {
        print('❌ [SOCKET DEBUG] Failed to parse random chat event data: $e');
        _errorController.add('Invalid random chat event format');
        return;
      }
    } else {
      print(
          '❌ [SOCKET DEBUG] Unexpected random chat event data type: ${data.runtimeType}');
      _errorController.add('Invalid random chat event data type');
      return;
    }

    print('   🔍 Event type: ${eventData['event']}');
    print('   📱 Session ID: ${eventData['sessionId']}');
    print('   💬 Chat Room ID: ${eventData['chatRoomId']}');

    // Automatically join the chat room when random chat event is received
    if (eventData['chatRoomId'] != null) {
      print(
          '🔌 [SOCKET DEBUG] Auto-joining chat room: ${eventData['chatRoomId']}');
      print('   📦 Event data: $eventData');
      joinChat(eventData['chatRoomId']);
    } else {
      print('❌ [SOCKET DEBUG] No chatRoomId in random chat event data');
      print('   📦 Available keys: ${eventData.keys.toList()}');
    }

    // Store the latest random chat event data
    _latestRandomChatData = eventData;
    _matchController.add(eventData);
    _eventController.add(SocketEvent.randomChatEvent);
  }

  // Store latest random chat event data for immediate access
  Map<String, dynamic>? _latestRandomChatData;

  // Get the latest random chat event data
  Map<String, dynamic>? get latestRandomChatData => _latestRandomChatData;
  
  // Store the latest timeout data for UI access
  Map<String, dynamic>? _latestTimeoutData;
  Map<String, dynamic>? get latestTimeoutData => _latestTimeoutData;

  // Handle random chat timeout event
  void _handleRandomChatTimeoutEvent(Map<String, dynamic> data) {
    print('⏰ [SOCKET DEBUG] Random chat timeout event received: $data');
    
    // Extract timeout information
    final String reason = data['reason'] ?? 'time_limit_exceeded';
    final String genderPreference = data['genderPreference'] ?? 'any';
    final String message = data['message'] ?? 'No match found. Please try again later.';
    
    print('🚫 [TIMEOUT DEBUG] Timeout reason: $reason');
    print('👤 [TIMEOUT DEBUG] Gender preference: $genderPreference');
    print('💬 [TIMEOUT DEBUG] Message: $message');
    
    // Add enhanced timeout data
    final timeoutData = {
      ...data,
      'reason': reason,
      'genderPreference': genderPreference,
      'message': message,
    };
    
    // Store timeout data for UI access
    _latestTimeoutData = timeoutData;
    
    _matchController.add(timeoutData);
    _eventController.add(SocketEvent.randomChatTimeout);
  }

  // Handle joined event
  void _handleJoinedEvent(dynamic data) {
    print('✅ [SOCKET DEBUG] Join confirmed by backend');
    print('   📦 Data type: ${data.runtimeType}');
    print('   📦 Data: $data');

    if (data == null) {
      print('⚠️ [SOCKET DEBUG] Joined event data is null (but this is OK)');
    }

    _eventController.add(SocketEvent.userJoined);
  }

  // Handle new message event
  void _handleNewMessageEvent(dynamic data) async {
    print('💬 [SOCKET DEBUG] _handleNewMessageEvent called');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] New message data is null');
        return;
      }

      if (data is! Map<String, dynamic>) {
        print(
            '❌ [SOCKET DEBUG] Invalid new message data type: ${data.runtimeType}');
        return;
      }

      final messageData = data['message'];
      if (messageData == null) {
        print('❌ [SOCKET DEBUG] Message data is null in new message event');
        return;
      }

      final message = Message.fromJson(messageData);

      // Check if we've already processed this message
      if (_processedMessageIds.contains(message.id)) {
        print('⏭️ [SOCKET DEBUG] Skipping duplicate message: ${message.id}');
        return;
      }

      // Get current user ID to check if this message is from the current user
      final currentUser = await _getCurrentUser();
      final currentUserId = currentUser?['uid'];

      print('🔍 [SOCKET DEBUG] Message sender: ${message.senderId}');
      print('🔍 [SOCKET DEBUG] Current user: $currentUserId');

      // Only add message if it's NOT from the current user (to avoid duplicates)
      if (currentUserId != null && message.senderId != currentUserId) {
        print('✅ [SOCKET DEBUG] Adding message from other user');
        _processedMessageIds.add(message.id);
        _messageController.add(message);
        _eventController.add(SocketEvent.message);
      } else if (currentUserId != null && message.senderId == currentUserId) {
        // This is a message from the current user via new_message event
        // Only add it if we haven't already processed it via message_sent
        if (!_processedMessageIds.contains(message.id)) {
          print(
              '✅ [SOCKET DEBUG] Adding message from current user (via new_message - no message_sent received)');
          _processedMessageIds.add(message.id);
          _messageController.add(message);
          _eventController.add(SocketEvent.message);
        } else {
          print(
              '⏭️ [SOCKET DEBUG] Skipping message from current user (already processed via message_sent)');
        }
      } else {
        print(
            '⏭️ [SOCKET DEBUG] Skipping message - current user ID not available');
      }
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling new message event: $e');
      print('   📦 Data that caused error: $data');
    }
  }

  // Handle message sent event
  void _handleMessageSentEvent(dynamic data) async {
    print('✅ [SOCKET DEBUG] _handleMessageSentEvent called');
    print('   📦 Data: $data');

    try {
      if (data == null) {
        print('❌ [SOCKET DEBUG] Message sent data is null');
        return;
      }

      if (data is! Map<String, dynamic>) {
        print(
            '❌ [SOCKET DEBUG] Invalid message sent data type: ${data.runtimeType}');
        return;
      }

      final messageData = data['message'];
      if (messageData == null) {
        print('❌ [SOCKET DEBUG] Message data is null in message sent event');
        return;
      }

      final message = Message.fromJson(messageData);

      // Check if we've already processed this message
      if (_processedMessageIds.contains(message.id)) {
        print('⏭️ [SOCKET DEBUG] Skipping duplicate message: ${message.id}');
        return;
      }

      // Get current user ID to confirm this is from the current user
      final currentUser = await _getCurrentUser();
      final currentUserId = currentUser?['uid'];

      print('🔍 [SOCKET DEBUG] Message sender: ${message.senderId}');
      print('🔍 [SOCKET DEBUG] Current user: $currentUserId');

      // Only add message if it's from the current user (confirmation)
      if (currentUserId != null && message.senderId == currentUserId) {
        print(
            '✅ [SOCKET DEBUG] Adding message from current user (confirmation)');
        _processedMessageIds.add(message.id);
        _messageController.add(message);
        _eventController.add(SocketEvent.message);
      } else {
        print(
            '⏭️ [SOCKET DEBUG] Skipping message_sent event - not from current user');
      }
    } catch (e) {
      print('❌ [SOCKET DEBUG] Error handling message sent event: $e');
      print('   📦 Data that caused error: $data');
    }
  }

  // Handle chat joined event
  void _handleChatJoinedEvent(dynamic data) {
    print('🔌 [SOCKET DEBUG] _handleChatJoinedEvent called');
    print('   📦 Data: $data');
    _eventController.add(SocketEvent.userJoined);
  }

  // Handle random chat session ended event
  void _handleRandomChatSessionEndedEvent(dynamic data) {
    print('🚪 [SOCKET DEBUG] Random chat session ended event received');
    print('   📦 Data: $data');
    _eventController.add(SocketEvent.randomChatSessionEnded);
  }

  // Handle random chat event received
  void _handleRandomChatEventReceived(dynamic data) {
    print('🎯 [SOCKET DEBUG] Random chat event received');
    print('   📦 Data: $data');
    _eventController.add(SocketEvent.randomChatEvent);
  }

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      // Reduced from 30 to 60 seconds
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

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send join event with Firebase user data
  void _sendJoinEvent() async {
    try {
      print('🔄 [SOCKET DEBUG] _sendJoinEvent called');
      // Import Firebase Auth at the top if not already imported
      final user = await _getCurrentUser();
      if (user != null) {
        final joinData = {
          'userId': user['uid'],
          'displayName': user['displayName'] ?? 'User',
          'photoURL': user['photoURL'],
        };

        print('📤 [SOCKET DEBUG] Sending join event');
        print('   📦 Data: $joinData');
        print('   👤 User ID: ${user['uid']}');
        print('   🏷️ Display Name: ${user['displayName']}');

        _sendToSocket({
          'event': 'join',
          'data': joinData,
        });
      } else {
        print('❌ [SOCKET DEBUG] No Firebase user found for join event');
      }
    } catch (error) {
      print('❌ [SOCKET DEBUG] Error sending join event: $error');
    }
  }

  // Get current Firebase user
  Future<Map<String, dynamic>?> _getCurrentUser() async {
    try {
      final user = FirebaseAuth.FirebaseAuth.instance.currentUser;
      print('🔍 [SOCKET DEBUG] Firebase Auth current user: ${user?.uid}');
      print(
          '🔍 [SOCKET DEBUG] Firebase Auth user display name: ${user?.displayName}');
      print('🔍 [SOCKET DEBUG] Firebase Auth user email: ${user?.email}');

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'displayName': user.displayName ?? 'User',
          'photoURL': user.photoURL,
        };
        print('✅ [SOCKET DEBUG] Returning user data: $userData');
        return userData;
      }
      print('❌ [SOCKET DEBUG] No Firebase user found');
      return null;
    } catch (error) {
      print('❌ [SOCKET DEBUG] Error getting current user: $error');
      return null;
    }
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
