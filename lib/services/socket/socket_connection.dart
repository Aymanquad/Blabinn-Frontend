import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../../core/config.dart';
import 'socket_types.dart';

class SocketConnection {
  IO.Socket? _socket;
  String? _authToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _intentionalDisconnect = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = AppConfig.wsMaxReconnectAttempts;
  final Duration _reconnectDelay = AppConfig.wsReconnectDelay;
  DateTime? _connectionTime;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  IO.Socket? get socket => _socket;
  String? get authToken => _authToken;

  // Initialize socket connection
  Future<void> connect(String authToken, Function(SocketEvent) onEvent) async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    _intentionalDisconnect = false;
    onEvent(SocketEvent.connect);

    try {
      _authToken = authToken;

      _socket = IO.io(
        AppConfig.wsBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': _authToken})
            .setTimeout(5000)
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        _connectionTime = DateTime.now();

        if (_reconnectAttempts > 0) {
          // Successfully reconnected
        }

        _reconnectAttempts = 0;
        _stopReconnectTimer();
        _startPingTimer();
        _startHeartbeat();
        onEvent(SocketEvent.connect);

        Timer(const Duration(milliseconds: 100), () {
          if (_isConnected) {
            _sendJoinEvent(onEvent);
          }
        });
      });

      _socket!.onDisconnect((reason) {
        _handleDisconnect(onEvent);
      });

      _socket!.onError((error) {
        _handleError(error, onEvent);
      });

      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      _handleError(e, onEvent);
    }
  }

  // Disconnect from socket
  Future<void> disconnect(Function(SocketEvent) onEvent) async {
    _intentionalDisconnect = true;
    _stopPingTimer();
    _stopReconnectTimer();
    _stopHeartbeat();

    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _isConnected = false;
    _isConnecting = false;
    onEvent(SocketEvent.disconnect);
  }

  // Handle disconnect
  void _handleDisconnect(Function(SocketEvent) onEvent) {
    _isConnected = false;
    _isConnecting = false;
    onEvent(SocketEvent.disconnect);

    if (!_intentionalDisconnect) {
      _attemptReconnect(onEvent);
    } else {
      _intentionalDisconnect = false;
    }
  }

  // Handle connection error
  void _handleError(dynamic error, Function(SocketEvent) onEvent) {
    _isConnected = false;
    _isConnecting = false;
    onEvent(SocketEvent.error);
    _attemptReconnect(onEvent);
  }

  // Attempt to reconnect
  void _attemptReconnect(Function(SocketEvent) onEvent) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && !_isConnecting && _authToken != null) {
        connect(_authToken!, onEvent).catchError((error) {
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _attemptReconnect(onEvent);
          }
        });
      }
    });
  }

  // Start ping timer for connection health
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

  // Send to socket
  void _sendToSocket(Map<String, dynamic> message) {
    if (_socket != null && _isConnected && _socket!.connected) {
      try {
        _socket!.emit(message['event'], message['data']);
        print('📤 [SOCKET DEBUG] Message sent: ${message['event']}');
      } catch (e) {
        print('❌ [SOCKET DEBUG] Error sending message: $e');
        _handleConnectionError();
      }
    } else {
      print('⚠️ [SOCKET DEBUG] Cannot send message - socket not connected');
    }
  }

  // Handle connection error specifically
  void _handleConnectionError() {
    _isConnected = false;
    _isConnecting = false;
  }

  // Send join event with Firebase user data
  void _sendJoinEvent(Function(SocketEvent) onEvent) async {
    try {
      final user = await _getCurrentUser();
      if (user != null) {
        final joinData = {
          'userId': user['uid'],
          'displayName': user['displayName'] ?? 'User',
          'photoURL': user['photoURL'],
        };

        _sendToSocket({
          'event': 'join',
          'data': joinData,
        });
      }
    } catch (error) {
      // Error handling
    }
  }

  // Get current Firebase user
  Future<Map<String, dynamic>?> _getCurrentUser() async {
    try {
      final user = FirebaseAuth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'displayName': user.displayName ?? 'User',
          'photoURL': user.photoURL,
        };
        return userData;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  // Send message to socket
  void sendToSocket(Map<String, dynamic> message) {
    _sendToSocket(message);
  }

  // Set up event listeners
  void setupEventListeners(Function(String, dynamic) onEvent) {
    if (_socket != null) {
      _socket!.onAny((event, data) {
        onEvent(event, data);
      });
    }
  }
}
