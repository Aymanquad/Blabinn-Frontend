import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import '../core/config.dart';
import 'firebase_auth_service.dart';

class RealtimeChatService {
  static final RealtimeChatService _instance = RealtimeChatService._internal();
  factory RealtimeChatService() => _instance;
  RealtimeChatService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentDisplayName;

  // Stream controllers for real-time events
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Message> _messageSentController =
      StreamController<Message>.broadcast();
  final StreamController<String> _userOnlineController =
      StreamController<String>.broadcast();
  final StreamController<String> _userOfflineController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Message> get messageSentStream => _messageSentController.stream;
  Stream<String> get userOnlineStream => _userOnlineController.stream;
  Stream<String> get userOfflineStream => _userOfflineController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      print('🔌 DEBUG: RealtimeChatService connecting to Socket.IO server...');
      print('🔌 DEBUG: Using WebSocket URL: ${AppConfig.wsBaseUrl}');

      // Get current user info
      final authService = FirebaseAuthService();
      final user = authService.currentUser;
      if (user == null) {
        print('❌ DEBUG: No authenticated user found');
        return;
      }

      _currentUserId = user.uid;
      _currentDisplayName = user.displayName ?? 'User';

      // Get auth token
      final authToken = await user.getIdToken();

      // Create socket connection to the backend
      _socket = IO.io(AppConfig.wsBaseUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'timeout': 20000,
        'auth': {
          'token': authToken,
        },
      });

      // Set up event listeners
      _setupEventListeners();

      // Connect
      _socket!.connect();
      print('🔌 DEBUG: RealtimeChatService Socket.IO connection initiated');
    } catch (e) {
      print('🚨 DEBUG: RealtimeChatService Socket.IO connection error: $e');
      _errorController
          .add({'error': 'Connection failed', 'details': e.toString()});
    }
  }

  void _setupEventListeners() {
    _socket!.on('connect', (_) {
      print('✅ DEBUG: RealtimeChatService Socket.IO connected successfully');
      print('✅ DEBUG: RealtimeChatService Socket ID: ${_socket!.id}');
      _isConnected = true;

      // Join the user room for private messaging
      print('📤 DEBUG: RealtimeChatService sending join event');
      _socket!.emit('join', {
        'userId': _currentUserId,
        'displayName': _currentDisplayName,
      });
    });

    _socket!.on('disconnect', (_) {
      print('❌ DEBUG: RealtimeChatService Socket.IO disconnected');
      _isConnected = false;
    });

    _socket!.on('joined', (data) {
      print('✅ DEBUG: Successfully joined chat room: $data');
    });

    _socket!.on('new_message', (data) {
      print('💬 DEBUG: Received new message: $data');
      try {
        final messageData = data['message'];
        final message = Message.fromJson(messageData);
        _messageController.add(message);
      } catch (e) {
        print('🚨 DEBUG: Error parsing received message: $e');
      }
    });

    _socket!.on('message_sent', (data) {
      print('✅ DEBUG: Message sent confirmation: $data');
      try {
        final messageData = data['message'];
        final message = Message.fromJson(messageData);
        _messageSentController.add(message);
      } catch (e) {
        print('🚨 DEBUG: Error parsing sent message confirmation: $e');
      }
    });

    _socket!.on('user_online', (data) {
      print('🟢 DEBUG: User came online: $data');
      final userId = data['userId'];
      if (userId != null) {
        _userOnlineController.add(userId);
      }
    });

    _socket!.on('user_offline', (data) {
      print('🔴 DEBUG: User went offline: $data');
      final userId = data['userId'];
      if (userId != null) {
        _userOfflineController.add(userId);
      }
    });

    _socket!.on('error', (data) {
      print('🚨 DEBUG: Socket.IO error: $data');
      _errorController.add(data);
    });

    _socket!.on('connect_error', (error) {
      print('🚨 DEBUG: Socket.IO connect error: $error');
      _errorController
          .add({'error': 'Connect error', 'details': error.toString()});
    });
  }

  void sendMessage(String receiverId, String content) {
    if (!_isConnected || _socket == null) {
      print('❌ DEBUG: Cannot send message - not connected');
      _errorController
          .add({'error': 'Not connected', 'details': 'Socket not connected'});
      return;
    }

    print('📤 DEBUG: Sending message via Socket.IO');
    _socket!.emit('message', {
      'receiverId': receiverId,
      'content': content,
      'messageType': 'text',
    });
  }

  void markMessageAsRead(String messageId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('mark_read', {
      'messageId': messageId,
    });
  }

  void sendTypingIndicator(String receiverId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('typing', {
      'receiverId': receiverId,
    });
  }

  void stopTypingIndicator(String receiverId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('stop_typing', {
      'receiverId': receiverId,
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
    print('🔌 DEBUG: Socket.IO disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _messageSentController.close();
    _userOnlineController.close();
    _userOfflineController.close();
    _errorController.close();
  }
}
