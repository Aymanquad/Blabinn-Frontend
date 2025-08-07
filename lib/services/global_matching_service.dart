import 'package:flutter/material.dart';
import 'dart:async';
import 'socket_service.dart';
import 'api_service.dart';
import '../app.dart'; // Import for navigatorKey

class GlobalMatchingService {
  static final GlobalMatchingService _instance = GlobalMatchingService._internal();
  factory GlobalMatchingService() => _instance;
  GlobalMatchingService._internal();

  // Global state
  bool _isMatching = false;
  bool _isConnected = false;
  String? _currentSessionId;
  String? _matchMessage;
  int _queueTime = 0;
  String _genderPreference = 'any';
  Map<String, dynamic> _filters = {};

  // Stream controllers for state changes
  final StreamController<bool> _matchingStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<String?> _messageController = StreamController<String?>.broadcast();
  final StreamController<int> _queueTimeController = StreamController<int>.broadcast();

  // Services
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  // Stream subscriptions
  StreamSubscription? _matchSubscription;
  StreamSubscription? _errorSubscription;

  // Getters
  bool get isMatching => _isMatching;
  bool get isConnected => _isConnected;
  String? get currentSessionId => _currentSessionId;
  String? get matchMessage => _matchMessage;
  int get queueTime => _queueTime;
  String get genderPreference => _genderPreference;
  Map<String, dynamic> get filters => _filters;

  // Streams
  Stream<bool> get matchingStateStream => _matchingStateController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String?> get messageStream => _messageController.stream;
  Stream<int> get queueTimeStream => _queueTimeController.stream;

  void initialize() {
    _setupSocketListeners();
    _initializeFilters();
  }

  void _setupSocketListeners() {
    _matchSubscription = _socketService.matchStream.listen(_handleMatchEvent);
    _errorSubscription = _socketService.errorStream.listen(_handleErrorEvent);

    _socketService.eventStream.listen((event) {
      if (event == SocketEvent.randomChatEvent) {
        final data = _socketService.latestRandomChatData;
        if (data != null) {
          _handleRandomChatEvent(data);
        }
      } else if (event == SocketEvent.randomChatTimeout) {
        _handleRandomChatTimeout();
      }
    });
  }

  void _initializeFilters() {
    _filters = {
      'distance': '1-5',
      'language': 'any',
      'ageRange': 'all',
      'interests': [],
    };
    _genderPreference = 'any';
  }

  void _handleMatchEvent(Map<String, dynamic> data) {
    final event = data['event'];

    if (event == 'match_found') {
      final sessionId = data['sessionId'];
      final chatRoomId = data['chatRoomId'];

      _currentSessionId = sessionId;
      _isMatching = false;
      _isConnected = true;
      _matchMessage = 'Match found! Starting chat...';
      _notifyStateChanges();

      _navigateToChat(sessionId, chatRoomId);
    } else if (event == 'match_timeout') {
      String timeoutMessage;
      final String reason = data['reason'] ?? 'time_limit_exceeded';
      final String genderPreference = data['genderPreference'] ?? 'any';

      if (reason == 'no_gender_compatible_users') {
        timeoutMessage =
            'No $genderPreference users found after 5 minutes. Please try again later.';
      } else {
        timeoutMessage = genderPreference == 'any'
            ? 'No match found within 5 minutes. Please try again later.'
            : 'No match found with your gender preference ($genderPreference) within 5 minutes. Please try again later.';
      }

      _isMatching = false;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = timeoutMessage;
      _notifyStateChanges();
    }
  }

  void _handleErrorEvent(String error) {
    String errorMessage = error;
    String errorCode = '';
    String sessionId = '';
    String chatRoomId = '';

    if (error.contains('|')) {
      final parts = error.split('|');
      if (parts.length >= 4) {
        errorMessage = parts[0];
        errorCode = parts[1];
        sessionId = parts[2];
        chatRoomId = parts[3];
      }
    }

    if (errorCode == 'ALREADY_IN_SESSION' ||
        errorMessage.contains('ALREADY_IN_SESSION')) {
      _isMatching = false;
      _isConnected = false;
      _currentSessionId = sessionId.isNotEmpty ? sessionId : null;
      _matchMessage = 'You already have an active chat session.';
      _notifyStateChanges();
      return;
    } else if (errorCode == 'ALREADY_IN_QUEUE' ||
        errorMessage.contains('ALREADY_IN_QUEUE')) {
      _isMatching = true;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = 'You are already in the matching queue. Please wait...';
      _notifyStateChanges();
      return;
    }

    _isMatching = false;
    _isConnected = false;
    _matchMessage = 'Connection error: $error';
    _notifyStateChanges();
  }

  void _handleRandomChatEvent(Map<String, dynamic> data) {
    final event = data['event'];
    final sessionId = data['sessionId'];
    final chatRoomId = data['chatRoomId'];

    print('🎯 [GLOBAL MATCHING DEBUG] Random chat event received: $event');
    print('🎯 [GLOBAL MATCHING DEBUG] Session ID: $sessionId');
    print('🎯 [GLOBAL MATCHING DEBUG] Chat Room ID: $chatRoomId');

    switch (event) {
      case 'session_started':
        if (sessionId != null && chatRoomId != null) {
          _currentSessionId = sessionId;
          _isMatching = false;
          _isConnected = true;
          _matchMessage = 'Match found! Starting chat...';
          _notifyStateChanges();

          _navigateToChat(sessionId, chatRoomId);
        } else {
          print('❌ [GLOBAL MATCHING DEBUG] Missing session or chat room ID');
          _isMatching = false;
          _matchMessage = 'Error: Invalid session data';
          _notifyStateChanges();
        }
        break;
      
      case 'session_failed':
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = 'Failed to start chat session. Please try again.';
        _notifyStateChanges();
        break;
      
      case 'partner_joined':
        if (sessionId != null && chatRoomId != null) {
          _currentSessionId = sessionId;
          _isMatching = false;
          _isConnected = true;
          _matchMessage = 'Partner joined! Chat is ready.';
          _notifyStateChanges();
        }
        break;
      
      case 'partner_left':
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = 'Partner left before chat started. Please try again.';
        _notifyStateChanges();
        break;
      
      default:
        print('⚠️ [GLOBAL MATCHING DEBUG] Unknown random chat event: $event');
        break;
    }
  }

  void _handleRandomChatTimeout() {
    final timeoutData = _socketService.latestTimeoutData;
    String timeoutMessage;

    if (timeoutData != null) {
      final String reason = timeoutData['reason'] ?? 'time_limit_exceeded';
      final String timeoutGenderPreference = timeoutData['genderPreference'] ?? _genderPreference;

      if (reason == 'no_gender_compatible_users') {
        timeoutMessage =
            'No $timeoutGenderPreference users found after 5 minutes. Please try again later.';
      } else {
        timeoutMessage = timeoutGenderPreference == 'any'
            ? 'No match found within 5 minutes. Please try again later.'
            : 'No match found with your gender preference ($timeoutGenderPreference) within 5 minutes. Please try again later.';
      }
    } else {
      timeoutMessage = _genderPreference == 'any'
          ? 'No match found within 5 minutes. Please try again later.'
          : 'No match found with your gender preference ($_genderPreference) within 5 minutes. Please try again later.';
    }

    _isMatching = false;
    _isConnected = false;
    _currentSessionId = null;
    _matchMessage = timeoutMessage;
    _notifyStateChanges();
  }

  void _navigateToChat(String sessionId, String chatRoomId) {
    try {
      print('🚀 [GLOBAL MATCHING DEBUG] Navigating to random chat from global service');
      print('   📱 Session ID: $sessionId');
      print('   💬 Chat Room ID: $chatRoomId');
      
      // Use dynamic navigation to avoid import issues
      navigatorKey.currentState?.pushNamed(
        '/random-chat',
        arguments: {
          'sessionId': sessionId,
          'chatRoomId': chatRoomId,
        },
      ).then((_) {
        print('🔙 [GLOBAL MATCHING DEBUG] Returned from RandomChatScreen, resetting state');
        // When returning from random chat, reset state
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = null;
        _notifyStateChanges();
      }).catchError((error) {
        print('❌ [GLOBAL MATCHING DEBUG] Navigation error: $error');
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = 'Navigation error. Please try again.';
        _notifyStateChanges();
      });
    } catch (e) {
      print('❌ [GLOBAL MATCHING DEBUG] Error during navigation: $e');
      _isMatching = false;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = 'Error starting chat. Please try again.';
      _notifyStateChanges();
    }
  }

  void _notifyStateChanges() {
    _matchingStateController.add(_isMatching);
    _connectionStateController.add(_isConnected);
    _messageController.add(_matchMessage);
    _queueTimeController.add(_queueTime);
  }

  Future<void> startMatching() async {
    if (_isMatching || _isConnected) {
      return;
    }

    try {
      _isMatching = true;
      _matchMessage = null;
      _queueTime = 0;
      _notifyStateChanges();

      final userInterests = _filters['interests']?.cast<String>() ?? [];

      if (_genderPreference.isEmpty) {
        _genderPreference = 'any';
      }

      await _socketService.startRandomConnection(
        country: _filters['region'],
        language: _filters['language'],
        interests: userInterests,
        genderPreference: _genderPreference,
      );

      _startQueueTimer();
    } catch (e) {
      _isMatching = false;
      _matchMessage = 'Error: ${e.toString()}';
      _notifyStateChanges();
    }
  }

  void _startQueueTimer() {
    if (!_isMatching) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (_isMatching) {
        _queueTime++;
        _notifyStateChanges();
        _startQueueTimer();
      }
    });
  }

  Future<void> stopMatching() async {
    if (!_isMatching && !_isConnected) return;

    try {
      _isMatching = false;
      _isConnected = false;
      _queueTime = 0;
      _notifyStateChanges();

      await _socketService.stopRandomConnection();
    } catch (e) {
      // Handle error
    }
  }

  void setGenderPreference(String preference) {
    _genderPreference = preference;
  }

  void setFilters(Map<String, dynamic> filters) {
    _filters = filters;
  }

  void loadUserInterests() async {
    try {
      final currentUserId = await _apiService.getCurrentUserId();
      if (currentUserId == null) {
        return;
      }

      final profileData = await _apiService.getUserProfile(currentUserId);
      final userInterests = profileData['interests'];

      if (userInterests != null && userInterests is List) {
        _filters['interests'] = List<String>.from(userInterests);
      }
    } catch (e) {
      // Keep default empty interests array if loading fails
    }
  }

  void dispose() {
    _matchSubscription?.cancel();
    _errorSubscription?.cancel();
    _matchingStateController.close();
    _connectionStateController.close();
    _messageController.close();
    _queueTimeController.close();
    stopMatching();
  }
} 