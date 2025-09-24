import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'socket_service.dart';
import 'api_service.dart';
import '../app.dart'; // Import for navigatorKey
import '../widgets/match_popup.dart';
import '../models/user.dart';

class GlobalMatchingService {
  static final GlobalMatchingService _instance =
      GlobalMatchingService._internal();
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
  final StreamController<bool> _matchingStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _messageController =
      StreamController<String?>.broadcast();
  final StreamController<int> _queueTimeController =
      StreamController<int>.broadcast();

  // Services
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  // Stream subscriptions
  StreamSubscription<Map<String, dynamic>>? _matchSubscription;
  StreamSubscription<String>? _errorSubscription;

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
      'interests': <String>[],
    };
    _genderPreference = 'any';
  }

  void _handleMatchEvent(Map<String, dynamic> data) {
    final event = data['event'];

    if (event == 'match_found') {
      final sessionId = data['sessionId'] as String?;
      final chatRoomId = data['chatRoomId'] as String?;

      if (sessionId != null && chatRoomId != null) {
        _currentSessionId = sessionId;
        _isMatching = false;
        _isConnected = true;
        _matchMessage = 'Match found! Starting chat...';
        _notifyStateChanges();

        _navigateToChat(sessionId, chatRoomId);
      }
    } else if (event == 'match_timeout') {
      String timeoutMessage;
      final String reason = data['reason'] as String? ?? 'time_limit_exceeded';
      final String genderPreference =
          data['genderPreference'] as String? ?? 'any';

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
    // String chatRoomId = ''; // Unused

    if (error.contains('|')) {
      final parts = error.split('|');
      if (parts.length >= 4) {
        errorMessage = parts[0];
        errorCode = parts[1];
        sessionId = parts[2];
        // chatRoomId = parts[3]; // Unused
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
        final sessionIdStr = sessionId as String?;
        final chatRoomIdStr = chatRoomId as String?;
        if (sessionIdStr != null && chatRoomIdStr != null) {
          _currentSessionId = sessionIdStr;
          _isMatching = false;
          _isConnected = true;
          _matchMessage = 'Match found! Starting chat...';
          _notifyStateChanges();

          _navigateToChat(sessionIdStr, chatRoomIdStr);
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
        final sessionIdStr = sessionId as String?;
        final chatRoomIdStr = chatRoomId as String?;
        if (sessionIdStr != null && chatRoomIdStr != null) {
          _currentSessionId = sessionIdStr;
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
      final String reason =
          timeoutData['reason'] as String? ?? 'time_limit_exceeded';
      final String timeoutGenderPreference =
          timeoutData['genderPreference'] as String? ?? _genderPreference;

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

  void _navigateToChat(String sessionId, String chatRoomId) async {
    try {
      print(
          '🚀 [GLOBAL MATCHING DEBUG] Preparing to show match popup and navigate to chat');
      print('   📱 Session ID: $sessionId');
      print('   💬 Chat Room ID: $chatRoomId');

      // Get matched user details
      final matchedUser = await _getMatchedUserDetails(sessionId);

      if (matchedUser != null) {
        // Show match popup first
        await _showMatchPopup(matchedUser, sessionId, chatRoomId);
      } else {
        // Fallback: navigate directly to chat if we can't get user details
        _navigateDirectlyToChat(sessionId, chatRoomId);
      }
    } catch (e) {
      print('❌ [GLOBAL MATCHING DEBUG] Error during navigation: $e');
      _isMatching = false;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = 'Error starting chat. Please try again.';
      _notifyStateChanges();
    }
  }

  Future<User?> _getMatchedUserDetails(String sessionId) async {
    try {
      print(
          '🔍 [GLOBAL MATCHING DEBUG] Fetching matched user details for session: $sessionId');

      // Try multiple times with delay in case session data isn't ready yet
      for (int attempt = 1; attempt <= 3; attempt++) {
        print('🔍 [GLOBAL MATCHING DEBUG] Attempt $attempt to get session data');
        
        // Try to get partner info from the session
        final responseData = await _apiService.getActiveRandomChatSession();
        print('🔍 [GLOBAL MATCHING DEBUG] Response data (attempt $attempt): $responseData');
        
        // Extract session data from response
        final sessionData = responseData['session'] as Map<String, dynamic>?;
        print('🔍 [GLOBAL MATCHING DEBUG] Session data (attempt $attempt): $sessionData');
      
      if (sessionData != null && sessionData['sessionId'] == sessionId) {
        // Get current user ID to find the partner
        final currentUserId = FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;
        print('🔍 [GLOBAL MATCHING DEBUG] Current user ID: $currentUserId');
        String? partnerId;
        
        // First try the direct partnerId field (for backward compatibility)
        partnerId = sessionData['partnerId'] as String?;
        print('🔍 [GLOBAL MATCHING DEBUG] Direct partnerId: $partnerId');
        
        // If no direct partnerId, extract from participants array
        if (partnerId?.isEmpty != false && currentUserId != null) {
          final participants = sessionData['participants'] as List<dynamic>?;
          print('🔍 [GLOBAL MATCHING DEBUG] Participants: $participants');
          if (participants != null && participants.isNotEmpty) {
            // Find the participant that is not the current user
            for (final participant in participants) {
              print('🔍 [GLOBAL MATCHING DEBUG] Checking participant: $participant vs current: $currentUserId');
              if (participant != currentUserId) {
                partnerId = participant as String?;
                print('🔍 [GLOBAL MATCHING DEBUG] Found partner in participants: $partnerId');
                break;
              }
            }
          }
        }
        
        if (partnerId?.isNotEmpty == true) {
          print('🔍 [GLOBAL MATCHING DEBUG] Fetching user profile for partner ID: $partnerId');
          final userProfile = await _apiService.getUserProfile(partnerId!);
          print('🔍 [GLOBAL MATCHING DEBUG] User profile: $userProfile');
          if (userProfile?.isNotEmpty == true) {
            return User.fromJson(userProfile);
          }
        } else {
          print('❌ [GLOBAL MATCHING DEBUG] No partner ID found on attempt $attempt');
        }
      } else {
        print('❌ [GLOBAL MATCHING DEBUG] Session data null or sessionId mismatch on attempt $attempt');
      }
      
      // If this attempt failed and we have more attempts, wait and try again
      if (attempt < 3) {
        print('⏳ [GLOBAL MATCHING DEBUG] Waiting 1 second before retry...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

      // Fallback: create a demo user for testing
      print('🔍 [GLOBAL MATCHING DEBUG] Creating demo user for match popup');
      return User(
        id: 'demo_matched_user_${DateTime.now().millisecondsSinceEpoch}',
        username: 'Chat Partner',
        email: null,
        bio: 'Ready to chat with you!',
        profileImage: null,
        interests: ['chatting', 'meeting new people'],
        language: 'en',
        location: null,
        latitude: null,
        longitude: null,
        isOnline: true,
        lastSeen: DateTime.now(),
        isPremium: false,
        adsFree: false,
        credits: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBlocked: false,
        isFriend: false,
        deviceId: null,
        age: 25,
        gender: 'Other',
        userType: 'guest',
        isVerified: false,
        verificationDate: null,
        connectCount: 0,
        pageSwitchCount: 0,
        lastPageSwitchTime: null,
        dailyAdViews: 0,
        lastAdViewDate: null,
        superLikesUsed: 0,
        boostsUsed: 0,
        friendsCount: 0,
        whoLikedViews: 0,
        lastWhoLikedViewDate: null,
      );
    } catch (e) {
      print('❌ [GLOBAL MATCHING DEBUG] Error fetching user details: $e');
      return null;
    }
  }

  Future<void> _showMatchPopup(
      User matchedUser, String sessionId, String chatRoomId) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('❌ [GLOBAL MATCHING DEBUG] No context available for popup');
        _navigateDirectlyToChat(sessionId, chatRoomId);
        return;
      }

      print(
          '✨ [GLOBAL MATCHING DEBUG] Showing match popup for user: ${matchedUser.username}');

      await showMatchPopup(
        context: context,
        matchedUser: matchedUser,
        onContinueChat: () {
          _navigateDirectlyToChat(sessionId, chatRoomId);
        },
        onAddFriend: () async {
          try {
            // Check if this is a demo user
            if (matchedUser.id.startsWith('demo_matched_user_')) {
              print('❌ [GLOBAL MATCHING DEBUG] Cannot send friend request to demo user');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot send friend request to demo users. Connect with real people first!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            
            await _apiService.sendFriendRequest(
              matchedUser.id,
              message:
                  'Hi! I met you in a random chat and would like to connect.',
              type: 'random_chat',
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Friend request sent successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            print('❌ [GLOBAL MATCHING DEBUG] Error sending friend request: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send friend request: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        onSkip: () {
          _navigateDirectlyToChat(sessionId, chatRoomId);
        },
      );
    } catch (e) {
      print('❌ [GLOBAL MATCHING DEBUG] Error showing match popup: $e');
      _navigateDirectlyToChat(sessionId, chatRoomId);
    }
  }

  void _navigateDirectlyToChat(String sessionId, String chatRoomId) {
    try {
      print('🚀 [GLOBAL MATCHING DEBUG] Navigating directly to random chat');

      // Use dynamic navigation to avoid import issues
      navigatorKey.currentState?.pushNamed(
        '/random-chat',
        arguments: {
          'sessionId': sessionId,
          'chatRoomId': chatRoomId,
        },
      ).then((_) {
        print(
            '🔙 [GLOBAL MATCHING DEBUG] Returned from RandomChatScreen, resetting state');
        // When returning from random chat, reset state
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = null;
        _notifyStateChanges();
      }).catchError((Object error) {
        print('❌ [GLOBAL MATCHING DEBUG] Navigation error: $error');
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = 'Navigation error. Please try again.';
        _notifyStateChanges();
      });
    } catch (e) {
      print('❌ [GLOBAL MATCHING DEBUG] Error during direct navigation: $e');
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

      final userInterests =
          (_filters['interests'] as List<dynamic>?)?.cast<String>() ??
              <String>[];

      if (_genderPreference.isEmpty) {
        _genderPreference = 'any';
      }

      await _socketService.startRandomConnection(
        country: _filters['region'] as String?,
        language: _filters['language'] as String?,
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
