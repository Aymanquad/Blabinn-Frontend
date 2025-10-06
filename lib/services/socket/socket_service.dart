import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../../core/constants.dart';
import '../../core/config.dart';
import '../../models/message.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../notification_service.dart';
import '../background_image_service.dart';
import '../api_service.dart';
import 'socket_types.dart';
import 'socket_connection.dart';
import 'socket_message_handlers.dart';
import 'socket_event_handlers.dart';
import 'socket_random_chat_handlers.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Components
  final SocketConnection _connection = SocketConnection();
  final SocketMessageHandlers _messageHandlers = SocketMessageHandlers();
  final SocketEventHandlers _eventHandlers = SocketEventHandlers();
  final SocketRandomChatHandlers _randomChatHandlers =
      SocketRandomChatHandlers();

  // Services
  final NotificationService _notificationService = NotificationService();
  final BackgroundImageService _backgroundImageService =
      BackgroundImageService();
  final ApiService _apiService = ApiService();

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
  bool get isConnected => _connection.isConnected;
  bool get isConnecting => _connection.isConnecting;
  Stream<SocketEvent> get eventStream => _eventController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Chat> get chatStream => _chatController.stream;
  Stream<User> get userStream => _userController.stream;
  Stream<String> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get matchStream => _matchController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Get current chat user
  String? get currentChatWithUserId => _messageHandlers.currentChatWithUserId;

  // Get the latest random chat event data
  Map<String, dynamic>? get latestRandomChatData =>
      _randomChatHandlers.latestRandomChatData;

  // Store the latest timeout data for UI access
  Map<String, dynamic>? get latestTimeoutData =>
      _randomChatHandlers.latestTimeoutData;

  // Initialize socket connection
  Future<void> connect(String authToken) async {
    await _connection.connect(authToken, (event) {
      _eventController.add(event);
    });

    _connection.setupEventListeners((event, data) {
      _handleSocketEvent(event, data);
    });
  }

  // Disconnect from socket
  Future<void> disconnect() async {
    await _connection.disconnect((event) {
      _eventController.add(event);
    });
  }

  // Handle Socket.IO events
  void _handleSocketEvent(String event, dynamic data) {
    _eventHandlers.handleSocketEvent(
      event,
      data,
      _eventController,
      _messageController,
      _chatController,
      _userController,
      _typingController,
      _matchController,
      _errorController,
      (data) => _messageHandlers.handleIncomingMessage(
          data, _messageController, _eventController),
      (data) => _messageHandlers.handleNewMessageEvent(
          data, _messageController, _eventController),
      (data) => _messageHandlers.handleMessageSentEvent(
          data, _messageController, _eventController),
      (data) => _randomChatHandlers.handleUserOnlineEvent(
          data, _userController, _eventController),
      (data) => _randomChatHandlers.handleUserOfflineEvent(
          data, _userController, _eventController),
      (data) => _randomChatHandlers.handleNewChatEvent(
          data, _chatController, _eventController),
      (data) => _randomChatHandlers.handleChatUpdatedEvent(
          data, _chatController, _eventController),
      (data) => _randomChatHandlers.handleMatchFoundEvent(
          data, _matchController, _eventController),
      (data) => _randomChatHandlers.handleRandomChatEvent(
          data, _matchController, _eventController, joinChat),
      (data) => _randomChatHandlers.handleRandomChatTimeoutEvent(
          data, _matchController, _eventController),
      (data) => _randomChatHandlers.handleJoinedEvent(data, _eventController),
      (data) =>
          _randomChatHandlers.handleChatJoinedEvent(data, _eventController),
      (data) => _randomChatHandlers.handleRandomChatSessionEndedEvent(
          data, _eventController),
      (data) => _randomChatHandlers.handleRandomChatEventReceived(
          data, _eventController),
    );
  }

  // Set current chat user (called when entering a chat)
  void setCurrentChatUser(String? userId) {
    _messageHandlers.setCurrentChatUser(userId);
  }

  // Clear current chat user (called when leaving a chat)
  void clearCurrentChatUser() {
    _messageHandlers.clearCurrentChatUser();
  }

  // Send message through socket (for random chat)
  Future<void> sendMessage(String chatId, String content,
      {MessageType type = MessageType.text}) async {
    if (!_connection.isConnected) {
      throw Exception('WebSocket not connected');
    }

    final currentUserId =
        FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      throw Exception('Unable to send message: missing user identity');
    }

    final messageType = type.toString().split('.').last;

    final message = {
      'event': 'send_message',
      'data': {
        'chatId': chatId,
        'chatRoomId': chatId,
        'message': content,
        'content': content,
        'userId': currentUserId,
        'type': messageType,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _connection.sendToSocket(message);
  }


  // Send message to friend (for friend chat)
  Future<void> sendFriendMessage(String receiverId, String content,
      {MessageType type = MessageType.text}) async {
    if (!_connection.isConnected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'receiverId': receiverId,
      'content': content,
      'messageType': type.toString().split('.').last,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Use the Socket.IO emit method directly for friend messages
    _connection.socket!.emit('message', message);
  }

  // Send image message to friend
  Future<void> sendFriendImageMessage(
      String receiverId, String imageUrl) async {
    if (!_connection.isConnected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'receiverId': receiverId,
      'content': '',
      'imageUrl': imageUrl,
      'messageType': 'image',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Use the Socket.IO emit method directly for friend image messages
    _connection.socket!.emit('message', message);
  }

  // Send typing indicator
  Future<void> sendTyping(String chatId) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'typing',
      'data': {
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _connection.sendToSocket(message);
  }

  // Send stop typing indicator
  Future<void> sendStopTyping(String chatId) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'stop_typing',
      'data': {
        'chatId': chatId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _connection.sendToSocket(message);
  }

  // Join chat room
  Future<void> joinChat(String chatId) async {
    if (!_connection.isConnected) {
      return;
    }

    final currentUserId =
        FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      print('[SOCKET DEBUG] Cannot join chat - missing user ID');
      return;
    }

    final message = {
      'event': 'join_chat',
      'data': {
        'chatRoomId': chatId,
        'chatId': chatId,
        'userId': currentUserId,
      },
    };

    _connection.sendToSocket(message);
  }



  // Leave chat room
  Future<void> leaveChat(String chatId) async {
    try {
      // Check both connection flag and actual socket state
      final isActuallyConnected =
          _connection.isConnected && _connection.socket?.connected == true;

      if (!isActuallyConnected) {
        print('[SOCKET DEBUG] Cannot leave chat - socket not connected');
        return;
      }

      final currentUserId =
          FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null || currentUserId.isEmpty) {
        print('[SOCKET DEBUG] Cannot leave chat - missing user ID');
        return;
      }

      final message = {
        'event': 'leave_chat',
        'data': {
          'chatRoomId': chatId,
          'chatId': chatId,
          'userId': currentUserId,
        },
      };

      _connection.sendToSocket(message);
      print('[SOCKET DEBUG] Leave chat message sent for: $chatId');
    } catch (e) {
      print('[SOCKET DEBUG] Error leaving chat: $e');
      throw Exception('Failed to leave chat: $e');
    }
  }




  // Start random connection
  Future<void> startRandomConnection({
    String? country,
    String? language,
    List<String>? interests,
    String? genderPreference,
    String? userId,
  }) async {
    // Check both _isConnected flag AND actual socket state
    final isActuallyConnected =
        _connection.isConnected && _connection.socket?.connected == true;

    if (!isActuallyConnected) {
      // If socket is connected but flag is false, fix the flag
      if (_connection.socket?.connected == true && !_connection.isConnected) {
        // Connection flag would be managed by the connection class
      } else {
        return;
      }
    }

    final effectiveUserId =
        userId ?? FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      print('[SOCKET DEBUG] Cannot start random connection - missing user ID');
      return;
    }

    final message = {
      'event': 'start_random_connection',
      'data': {
        'userId': effectiveUserId,
        if (country != null) 'country': country,
        if (language != null) 'language': language,
        if (interests != null) 'interests': interests,
        if (genderPreference != null) 'genderPreference': genderPreference,
      },
    };

    _connection.sendToSocket(message);
  }

  Future<void> stopRandomConnection({String? userId}) async {
    try {
      // Check both connection flag and actual socket state
      final isActuallyConnected =
          _connection.isConnected && _connection.socket?.connected == true;

      if (!isActuallyConnected) {
        print('[SOCKET DEBUG] Cannot stop random connection - socket not connected');
        return;
      }

      final effectiveUserId =
          userId ?? FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        print('[SOCKET DEBUG] Cannot stop random connection - missing user ID');
        return;
      }

      final message = {
        'event': 'stop_random_connection',
        'data': {
          'userId': effectiveUserId,
        },
      };

      _connection.sendToSocket(message);
      print('[SOCKET DEBUG] Stop random connection message sent');
    } catch (e) {
      print('[SOCKET DEBUG] Error stopping random connection: $e');
      throw Exception('Failed to stop random connection: $e');
    }
  }




  // Send call request
  Future<void> sendCallRequest(String chatId, String callType) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'call_request',
      'data': {
        'chatId': chatId,
        'callType': callType, // 'audio' or 'video'
      },
    };

    _connection.sendToSocket(message);
  }

  // Accept call
  Future<void> acceptCall(String callId) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'call_accepted',
      'data': {
        'callId': callId,
      },
    };

    _connection.sendToSocket(message);
  }

  // Reject call
  Future<void> rejectCall(String callId) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'call_rejected',
      'data': {
        'callId': callId,
      },
    };

    _connection.sendToSocket(message);
  }

  // End call
  Future<void> endCall(String callId) async {
    if (!_connection.isConnected) return;

    final message = {
      'event': 'call_ended',
      'data': {
        'callId': callId,
      },
    };

    _connection.sendToSocket(message);
  }

  // End random chat session
  Future<void> endRandomChatSession(String sessionId, String reason,
      {String? userId}) async {
    try {
      // Check both connection flag and actual socket state
      final isActuallyConnected =
          _connection.isConnected && _connection.socket?.connected == true;

      if (!isActuallyConnected) {
        print('[SOCKET DEBUG] Cannot end random chat session - socket not connected');
        return;
      }

      final effectiveUserId =
          userId ?? FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;

      final message = {
        'event': 'end_random_chat_session',
        'data': {
          'sessionId': sessionId,
          'reason': reason,
          if (effectiveUserId != null && effectiveUserId.isNotEmpty)
            'userId': effectiveUserId,
        },
      };

      _connection.sendToSocket(message);
      print('[SOCKET DEBUG] End random chat session message sent');
    } catch (e) {
      print('[SOCKET DEBUG] Error ending random chat session: $e');
      throw Exception('Failed to end random chat session: $e');
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
