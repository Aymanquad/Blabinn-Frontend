import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/premium_service.dart';

class ConnectStateManager {
  bool isMatching = false;
  bool isConnected = false;
  Map<String, dynamic> filters = {};
  bool isPremium = false;
  String? currentSessionId;
  String? matchMessage;
  int queueTime = 0;
  String genderPreference = 'any';
  
  late ApiService apiService;
  late SocketService socketService;
  late StreamSubscription matchSubscription;
  late StreamSubscription errorSubscription;
  late AnimationController animationController;
  late Animation<double> scaleAnimation;

  // Callbacks for state changes
  final VoidCallback onStateChanged;
  final Function(String, String) onNavigateToChat;
  final VoidCallback onShowTimeoutDialog;
  final Function(String, Color) onShowWarningSnackBar;
  final VoidCallback onShowClearSessionDialog;

  ConnectStateManager({
    required this.onStateChanged,
    required this.onNavigateToChat,
    required this.onShowTimeoutDialog,
    required this.onShowWarningSnackBar,
    required this.onShowClearSessionDialog,
  });

  void initializeServices() {
    apiService = ApiService();
    socketService = SocketService();
  }

  void initializeAnimations(TickerProvider vsync) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    );
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    );
    animationController.forward();
  }

  void initializeFilters() {
    filters = {
      'distance': '1-5',
      'language': 'any',
      'ageRange': 'all',
      'interests': [],
    };
    genderPreference = 'any';
  }

  Future<void> loadUserInterests() async {
    try {
      final currentUserId = await apiService.getCurrentUserId();
      if (currentUserId == null) {
        return;
      }

      final profileData = await apiService.getUserProfile(currentUserId);
      final userInterests = profileData['interests'];

      if (userInterests != null && userInterests is List) {
        filters['interests'] = List<String>.from(userInterests);
        onStateChanged();
      }
    } catch (e) {
      // Keep default empty interests array if loading fails
    }
  }

  void setupSocketListeners() {
    matchSubscription = socketService.matchStream.listen(handleMatchEvent);
    errorSubscription = socketService.errorStream.listen(handleErrorEvent);

    socketService.eventStream.listen((event) {
      if (event == SocketEvent.randomChatEvent) {
        final data = socketService.latestRandomChatData;
        if (data != null) {
          handleRandomChatEvent(data);
        }
      } else if (event == SocketEvent.randomChatTimeout) {
        handleRandomChatTimeout();
      }
    });
  }

  void cleanupSocketListeners() {
    matchSubscription.cancel();
    errorSubscription.cancel();
  }

  void handleMatchEvent(Map<String, dynamic> data) {
    final event = data['event'];

    if (event == 'match_found') {
      final sessionId = data['sessionId'];
      final chatRoomId = data['chatRoomId'];

      currentSessionId = sessionId;
      isMatching = false;
      isConnected = true;
      matchMessage = 'Match found! Starting chat...';
      onStateChanged();

      onNavigateToChat(sessionId, chatRoomId);
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

      isMatching = false;
      isConnected = false;
      currentSessionId = null;
      matchMessage = timeoutMessage;
      onStateChanged();

      onShowTimeoutDialog();
    }
  }

  void handleErrorEvent(String error) {
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
      isMatching = false;
      isConnected = false;
      currentSessionId = sessionId.isNotEmpty ? sessionId : null;
      matchMessage = 'You already have an active chat session.';
      onStateChanged();
      onShowWarningSnackBar('You already have an active chat session.', Colors.orange);
      onShowClearSessionDialog();
      return;
    } else if (errorCode == 'ALREADY_IN_QUEUE' ||
        errorMessage.contains('ALREADY_IN_QUEUE')) {
      isMatching = true;
      isConnected = false;
      currentSessionId = null;
      matchMessage = 'You are already in the matching queue. Please wait...';
      onStateChanged();
      onShowWarningSnackBar('You are already in the matching queue. Please wait...', Colors.blue);
      return;
    }

    handleError(errorMessage);
  }

  void handleError(String error) {
    if (error.contains('timeout') || error.contains('Max reconnection')) {
      // Connection issue handling - this will be handled by the UI layer
    }

    isMatching = false;
    isConnected = false;
    matchMessage = 'Connection error: $error';
    onStateChanged();
  }

  Future<void> clearActiveSession() async {
    try {
      final result = await apiService.forceClearActiveSession();

      isMatching = false;
      isConnected = false;
      currentSessionId = null;
      matchMessage = null;
      onStateChanged();
    } catch (e) {
      // Handle error - this will be handled by the UI layer
    }
  }

  void handleRandomChatEvent(Map<String, dynamic> data) {
    final event = data['event'];
    final sessionId = data['sessionId'];
    final chatRoomId = data['chatRoomId'];

    print('🎯 [CONNECT DEBUG] Random chat event received: $event');
    print('🎯 [CONNECT DEBUG] Session ID: $sessionId');
    print('🎯 [CONNECT DEBUG] Chat Room ID: $chatRoomId');

    // Handle different event types
    switch (event) {
      case 'session_started':
        if (sessionId != null && chatRoomId != null) {
          currentSessionId = sessionId;
          isMatching = false;
          isConnected = true;
          matchMessage = 'Match found! Starting chat...';
          onStateChanged();

          onNavigateToChat(sessionId, chatRoomId);
        } else {
          print('❌ [CONNECT DEBUG] Missing session or chat room ID');
          isMatching = false;
          matchMessage = 'Error: Invalid session data';
          onStateChanged();
        }
        break;
      
      case 'session_failed':
        isMatching = false;
        isConnected = false;
        currentSessionId = null;
        matchMessage = 'Failed to start chat session. Please try again.';
        onStateChanged();
        break;
      
      case 'partner_joined':
        // Partner joined the session
        if (sessionId != null && chatRoomId != null) {
          currentSessionId = sessionId;
          isMatching = false;
          isConnected = true;
          matchMessage = 'Partner joined! Chat is ready.';
          onStateChanged();
        }
        break;
      
      case 'partner_left':
        // Partner left before session started
        isMatching = false;
        isConnected = false;
        currentSessionId = null;
        matchMessage = 'Partner left before chat started. Please try again.';
        onStateChanged();
        onShowTimeoutDialog();
        break;
      
      default:
        print('⚠️ [CONNECT DEBUG] Unknown random chat event: $event');
        // Don't change state for unknown events, just log them
        break;
    }
  }

  void handleRandomChatTimeout() {
    final timeoutData = socketService.latestTimeoutData;
    String timeoutMessage;

    if (timeoutData != null) {
      final String reason = timeoutData['reason'] ?? 'time_limit_exceeded';
      final String timeoutGenderPreference = timeoutData['genderPreference'] ?? genderPreference;

      if (reason == 'no_gender_compatible_users') {
        timeoutMessage =
            'No $timeoutGenderPreference users found after 5 minutes. Please try again later.';
      } else {
        timeoutMessage = timeoutGenderPreference == 'any'
            ? 'No match found within 5 minutes. Please try again later.'
            : 'No match found with your gender preference ($timeoutGenderPreference) within 5 minutes. Please try again later.';
      }
    } else {
      timeoutMessage = genderPreference == 'any'
          ? 'No match found within 5 minutes. Please try again later.'
          : 'No match found with your gender preference ($genderPreference) within 5 minutes. Please try again later.';
    }

    isMatching = false;
    isConnected = false;
    currentSessionId = null;
    matchMessage = timeoutMessage;
    onStateChanged();

    onShowTimeoutDialog();
  }

  Future<void> startMatching() async {
    if (isMatching || isConnected) {
      return;
    }

    try {
      isMatching = true;
      matchMessage = null;
      queueTime = 0;
      onStateChanged();

      final userInterests = filters['interests']?.cast<String>() ?? [];

      if (genderPreference.isEmpty) {
        genderPreference = 'any';
      }

      await socketService.startRandomConnection(
        country: filters['region'],
        language: filters['language'],
        interests: userInterests,
        genderPreference: genderPreference,
      );

      startQueueTimer();
    } catch (e) {
      isMatching = false;
      matchMessage = 'Error: ${e.toString()}';
      onStateChanged();
    }
  }

  void startQueueTimer() {
    if (!isMatching) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (isMatching) {
        queueTime++;
        onStateChanged();
        startQueueTimer();
      }
    });
  }

  Future<void> stopMatching() async {
    if (!isMatching && !isConnected) return;

    try {
      isMatching = false;
      isConnected = false;
      queueTime = 0;
      onStateChanged();

      await socketService.stopRandomConnection();
    } catch (e) {
      // Handle error
    }
  }

  void handleImmediateMatch(Map<String, dynamic> connection) {
    isMatching = false;
    isConnected = true;
    matchMessage = 'Match found immediately!';
    onStateChanged();
  }

  void dispose() {
    cleanupSocketListeners();
    stopMatching();
    animationController.dispose();
  }
} 