import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'socket_service.dart';
import 'api_service.dart';
import 'ai_chatbot_service.dart';
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

  // AI Chatbot fallback state
  bool _isAiChat = false;
  String? _currentUserId;
  Timer? _aiFallbackTimer;

  // Stream controllers for state changes
  final StreamController<bool> _matchingStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _messageController =
      StreamController<String?>.broadcast();
  final StreamController<int> _queueTimeController =
      StreamController<int>.broadcast();
  final StreamController<void> _showPersonalitySelectionController =
      StreamController<void>.broadcast();

  // Services
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  final AiChatbotService _aiChatbotService = AiChatbotService();

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
  bool get isAiChat => _isAiChat;

  // Streams
  Stream<bool> get matchingStateStream => _matchingStateController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String?> get messageStream => _messageController.stream;
  Stream<int> get queueTimeStream => _queueTimeController.stream;
  Stream<void> get showPersonalitySelectionStream =>
      _showPersonalitySelectionController.stream;

  void initialize() {
    _setupSocketListeners();
    _initializeFilters();
  }

  Future<void> _initializeSocketConnection() async {
    try {
      // Get Firebase auth token
      final currentUser = FirebaseAuth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get ID token for socket authentication
      final token = await currentUser.getIdToken();

      // Connect to socket
      await _socketService.connect(token ?? '');
      print('[SOCKET] Socket connection initialized successfully');
    } catch (e) {
      print('[SOCKET] Failed to initialize socket connection: $e');
      throw Exception('Failed to connect to chat server: $e');
    }
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
        print(
            '🔍 [GLOBAL MATCHING DEBUG] Attempt $attempt to get session data');

        // Try to get partner info from the session
        final responseData = await _apiService.getActiveRandomChatSession();
        print(
            '🔍 [GLOBAL MATCHING DEBUG] Response data (attempt $attempt): $responseData');

        // Extract session data from response
        final sessionData = responseData['session'] as Map<String, dynamic>?;
        print(
            '🔍 [GLOBAL MATCHING DEBUG] Session data (attempt $attempt): $sessionData');

        if (sessionData != null && sessionData['sessionId'] == sessionId) {
          // Get current user ID to find the partner
          final currentUserId =
              FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;
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
                print(
                    '🔍 [GLOBAL MATCHING DEBUG] Checking participant: $participant vs current: $currentUserId');
                if (participant != currentUserId) {
                  partnerId = participant as String?;
                  print(
                      '🔍 [GLOBAL MATCHING DEBUG] Found partner in participants: $partnerId');
                  break;
                }
              }
            }
          }

          if (partnerId?.isNotEmpty == true) {
            print(
                '🔍 [GLOBAL MATCHING DEBUG] Fetching user profile for partner ID: $partnerId');
            final userProfile = await _apiService.getUserProfile(partnerId!);
            print('🔍 [GLOBAL MATCHING DEBUG] User profile: $userProfile');
            if (userProfile.isNotEmpty) {
              return User.fromJson(userProfile);
            }
          } else {
            print(
                '❌ [GLOBAL MATCHING DEBUG] No partner ID found on attempt $attempt');
          }
        } else {
          print(
              '❌ [GLOBAL MATCHING DEBUG] Session data null or sessionId mismatch on attempt $attempt');
        }

        // If this attempt failed and we have more attempts, wait and try again
        if (attempt < 3) {
          print('⏳ [GLOBAL MATCHING DEBUG] Waiting 1 second before retry...');
          await Future<void>.delayed(const Duration(seconds: 1));
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
              print(
                  '❌ [GLOBAL MATCHING DEBUG] Cannot send friend request to demo user');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cannot send friend request to demo users. Connect with real people first!'),
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

            String errorMessage = 'Failed to send friend request';
            Color backgroundColor = Colors.red;

            // Provide specific error messages
            if (e.toString().contains('Friend request already sent')) {
              errorMessage = 'Friend request already sent to this user';
              backgroundColor = Colors.orange;
            } else if (e.toString().contains('Already friends')) {
              errorMessage = 'You are already friends with this user!';
              backgroundColor = Colors.green;
            } else if (e.toString().contains('User not found')) {
              errorMessage = 'User not found. They may have left the chat.';
              backgroundColor = Colors.orange;
            } else {
              errorMessage = 'Failed to send friend request: ${e.toString()}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: backgroundColor,
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
      // Get current user ID
      final currentUser = FirebaseAuth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      _currentUserId = currentUser.uid;
      _isMatching = true;
      _isAiChat = false;
      _matchMessage = null;
      _queueTime = 0;
      _notifyStateChanges();

      final userInterests =
          (_filters['interests'] as List<dynamic>?)?.cast<String>() ??
              <String>[];

      if (_genderPreference.isEmpty) {
        _genderPreference = 'any';
      }

      // Initialize socket connection first
      print('[SOCKET] Initializing socket connection...');
      await _initializeSocketConnection();

      // Set matching state in backend for AI fallback tracking
      try {
        await _aiChatbotService.setMatchingState(
          userId: _currentUserId!,
          preferences: {
            'gender': _genderPreference,
            'interests': userInterests,
            'filters': _filters,
          },
        );
        print('[AI_CHATBOT] Matching state set successfully');
      } catch (e) {
        print('[AI_CHATBOT] Failed to set matching state: $e');
        print('[AI_CHATBOT] Continuing with regular matching...');
      }

      await _socketService.startRandomConnection(
        userId: _currentUserId!,
        country: _filters['region'] as String?,
        language: _filters['language'] as String?,
        interests: userInterests,
        genderPreference: _genderPreference,
      );

      _startQueueTimer();
      _startAiFallbackTimer(); // Start AI fallback timer
    } catch (e) {
      _isMatching = false;
      _matchMessage = 'Error: ${e.toString()}';
      _notifyStateChanges();
    }
  }

  void _startQueueTimer() {
    if (!_isMatching) return;

    Future<void>.delayed(const Duration(seconds: 1), () {
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
      _isAiChat = false;
      _queueTime = 0;

      // Stop timers
      _aiFallbackTimer?.cancel();

      // Clear matching state from backend
      if (_currentUserId != null) {
        await _aiChatbotService.clearMatchingState(userId: _currentUserId!);
      }

      _notifyStateChanges();

      await _socketService.stopRandomConnection(userId: _currentUserId);
    } catch (e) {
      print('[AI_CHATBOT] Error stopping matching: $e');
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
    _aiFallbackTimer?.cancel();
    _matchingStateController.close();
    _connectionStateController.close();
    _messageController.close();
    _queueTimeController.close();
    _showPersonalitySelectionController.close();
    stopMatching();
  }

  // AI Chatbot Fallback Methods

  void _startAiFallbackTimer() {
    if (!_isMatching || _currentUserId == null) {
      print(
          '[AI_CHATBOT] Cannot start timer - isMatching: $_isMatching, userId: $_currentUserId');
      return;
    }

    print('[AI_CHATBOT] Starting AI fallback timer (5 seconds)');

    // Cancel any existing timer
    _aiFallbackTimer?.cancel();

    // Start checking for AI fallback after 10 seconds to match backend timeout
    _aiFallbackTimer = Timer(const Duration(seconds: 10), () {
      print(
          '[AI_CHATBOT] Timer callback triggered - isMatching: $_isMatching, isConnected: $_isConnected');
      if (_isMatching && !_isConnected) {
        print(
            '[AI_CHATBOT] 5-second timeout reached, checking for AI fallback');
        _checkForAiFallback();
      } else {
        print(
            '[AI_CHATBOT] Timer triggered but conditions not met - skipping AI fallback');
      }
    });
  }

  Future<void> _checkForAiFallback() async {
    if (!_isMatching || _isConnected || _currentUserId == null) return;

    try {
      print(
          '[AI_CHATBOT] 10-second timeout reached - showing personality selection');

      // Stop matching state but don't set connected yet
      _isMatching = false;
      _matchMessage = 'Choose your AI chat partner';
      _notifyStateChanges();

      // Trigger personality selection
      _showPersonalitySelectionController.add(null);
    } catch (e) {
      print('[AI_CHATBOT] Error triggering personality selection: $e');
      // If there's an error, fall back to automatic AI selection
      await _handleLocalAiFallback();
    }
  }

  // Method to handle personality selection
  Future<void> selectPersonality(Map<String, dynamic> personalityData) async {
    if (_currentUserId == null) {
      print('[AI_CHATBOT] Cannot select personality - no user ID');
      return;
    }

    try {
      print(
          '[AI_CHATBOT] Selected personality: ${personalityData['name']} (${personalityData['id']})');

      // Update message to show loading
      _matchMessage = 'Connecting to ${personalityData['name']}...';
      _notifyStateChanges();

      // Try to create AI session through backend API first
      try {
        // Create AI fallback session with selected personality
        final sessionData = {
          'user_id': _currentUserId!,
          'personality': personalityData['id'],
          'preferences': {
            'selected_personality': personalityData['id'],
            'personality_name': personalityData['name'],
          },
          'start_time': DateTime.now().toIso8601String(),
        };

        // Set matching state with personality preference
        await _aiChatbotService.setMatchingState(
          userId: _currentUserId!,
          preferences: sessionData['preferences'] as Map<String, dynamic>,
        );

        print('[AI_CHATBOT] Matching state set with selected personality');
      } catch (e) {
        print(
            '[AI_CHATBOT] Backend session creation failed, using local fallback: $e');
      }

      // Create AI user with selected personality
      final aiUser = User(
        id: 'ai_user_${personalityData['id']}_${DateTime.now().millisecondsSinceEpoch}',
        username: personalityData['name'] as String,
        email: null,
        bio: personalityData['bio'] as String,
        profileImage: null,
        interests:
            (personalityData['interests'] as List<dynamic>).cast<String>(),
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
        age: 25, // Will be randomized in backend
        gender: 'Other', // Will be randomized in backend
        userType: 'ai_chatbot',
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

      // Create session ID
      final aiSessionId =
          'personality_${personalityData['id']}_${DateTime.now().millisecondsSinceEpoch}';

      // Update state
      _isMatching = false;
      _isConnected = true;
      _isAiChat = true;
      _currentSessionId = aiSessionId;
      _matchMessage = 'Connected to ${personalityData['name']}!';

      // Stop socket connection
      await _socketService.stopRandomConnection(userId: _currentUserId);

      _notifyStateChanges();

      // Navigate to AI chat
      _navigateToAiChat(aiSessionId, aiUser,
          personalityId: personalityData['id'] as String?);

      print('[AI_CHATBOT] Personality selection completed successfully');
    } catch (e) {
      print('[AI_CHATBOT] Error selecting personality: $e');
      _isMatching = false;
      _matchMessage =
          'Error starting chat with ${personalityData['name']}. Please try again.';
      _notifyStateChanges();
    }
  }

  Future<void> _handleLocalAiFallback() async {
    try {
      print('[AI_CHATBOT] Creating local AI fallback...');

      // Create a fake AI session
      final aiSessionId = 'ai_session_${DateTime.now().millisecondsSinceEpoch}';

      // Create fake AI user profile
      final aiUser = User(
        id: 'ai_user_local_${DateTime.now().millisecondsSinceEpoch}',
        username: 'AI Chat Partner',
        email: null,
        bio: 'Ready to chat with you! I\'m an AI assistant here to help.',
        profileImage: null,
        interests: ['chatting', 'helping', 'conversation'],
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
        userType: 'ai_chatbot',
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

      // Stop matching
      _isMatching = false;
      _isConnected = true;
      _isAiChat = true;
      _currentSessionId = aiSessionId;
      _matchMessage = 'AI Chat Partner found! Starting chat...';

      // Stop timers
      _aiFallbackTimer?.cancel();

      // Stop socket connection
      await _socketService.stopRandomConnection(userId: _currentUserId);

      _notifyStateChanges();

      // Navigate to AI chat
      _navigateToAiChat(aiSessionId, aiUser);

      print('[AI_CHATBOT] Local AI fallback completed successfully');
    } catch (e) {
      print('[AI_CHATBOT] Error in local AI fallback: $e');
      _isMatching = false;
      _matchMessage = 'Error starting AI chat. Please try again.';
      _notifyStateChanges();
    }
  }

  Future<void> _handleAiFallback(Map<String, dynamic> response) async {
    try {
      final sessionData = response['session_data'] as Map<String, dynamic>?;
      final aiUserProfile =
          response['ai_user_profile'] as Map<String, dynamic>?;

      if (sessionData == null || aiUserProfile == null) {
        print('[AI_CHATBOT] Invalid AI fallback response');
        return;
      }

      // Stop matching
      _isMatching = false;
      _isConnected = true;
      _isAiChat = true;
      _currentSessionId = sessionData['session_id'] as String?;
      _matchMessage = 'Match found! Starting chat...';

      // Stop timers
      _aiFallbackTimer?.cancel();

      // Stop socket connection
      await _socketService.stopRandomConnection(userId: _currentUserId);

      _notifyStateChanges();

      // Convert AI profile to User model
      final aiUser = User.fromJson(
          _aiChatbotService.convertAiProfileToUser(aiUserProfile));

      // Navigate to AI chat
      _navigateToAiChat(sessionData['session_id'] as String, aiUser);
    } catch (e) {
      print('[AI_CHATBOT] Error handling AI fallback: $e');
      _isMatching = false;
      _matchMessage = 'Error starting AI chat. Please try again.';
      _notifyStateChanges();
    }
  }

  void _navigateToAiChat(String sessionId, User aiUser,
      {String? personalityId}) {
    try {
      print('[AI_CHATBOT] Navigating to AI chat with session: $sessionId');
      print('[AI_CHATBOT] Navigator key state: ${navigatorKey.currentState}');

      // Convert User object to Map for navigation
      final aiUserMap = {
        'id': aiUser.id,
        'username': aiUser.username,
        'bio': aiUser.bio,
        'profileImage': aiUser.profileImage,
        'interests': aiUser.interests,
        'language': aiUser.language,
        'isOnline': aiUser.isOnline,
        'lastSeen': aiUser.lastSeen?.toIso8601String(),
        'isPremium': aiUser.isPremium,
        'age': aiUser.age,
        'gender': aiUser.gender,
        'userType': aiUser.userType,
        'isVerified': aiUser.isVerified,
      };

      print('[AI_CHATBOT] AI User Map: $aiUserMap');

      // Use dynamic navigation to avoid import issues
      navigatorKey.currentState?.pushNamed(
        '/random-chat',
        arguments: {
          'sessionId': sessionId,
          'chatRoomId': sessionId, // Use session ID as chat room ID for AI
          'isAiChat': true,
          'aiUser': aiUserMap,
          'personalityId': personalityId,
        },
      ).then((_) {
        print('[AI_CHATBOT] Returned from AI chat, resetting state');
        // When returning from AI chat, reset state
        _isMatching = false;
        _isConnected = false;
        _isAiChat = false;
        _currentSessionId = null;
        _matchMessage = null;
        _notifyStateChanges();
      }).catchError((Object error) {
        print('[AI_CHATBOT] Navigation error: $error');
        _isMatching = false;
        _isConnected = false;
        _isAiChat = false;
        _currentSessionId = null;
        _matchMessage = 'Navigation error. Please try again.';
        _notifyStateChanges();
      });
    } catch (e) {
      print('[AI_CHATBOT] Error during AI chat navigation: $e');
      _isMatching = false;
      _isConnected = false;
      _isAiChat = false;
      _currentSessionId = null;
      _matchMessage = 'Error starting AI chat. Please try again.';
      _notifyStateChanges();
    }
  }

  // Method to send message to AI chatbot
  Future<Map<String, dynamic>?> sendAiMessage(String message) async {
    if (!_isAiChat || _currentUserId == null) {
      print('[AI_CHATBOT] Not in AI chat or user ID missing');
      return null;
    }

    try {
      print('[AI_CHATBOT] Sending message to AI: $message');

      final response = await _aiChatbotService.sendAiMessage(
        userId: _currentUserId!,
        sessionId: _currentSessionId ?? '',
        message: message,
      );

      if (response['success'] == true) {
        print('[AI_CHATBOT] Message sent to AI successfully');
        return response;
      } else {
        print(
            '[AI_CHATBOT] Failed to send message to AI: ${response['error']}');
        return null;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error sending message to AI: $e');
      return null;
    }
  }

  // Method to end AI chat
  Future<bool> endAiChat() async {
    if (!_isAiChat || _currentUserId == null) {
      return false;
    }

    try {
      print('[AI_CHATBOT] Ending AI chat');

      final success = await _aiChatbotService.endAiSession(
        userId: _currentUserId!,
        sessionId: _currentSessionId ?? _currentUserId!,
      );

      if (success) {
        print('[AI_CHATBOT] AI chat ended successfully');
        _isAiChat = false;
        _isConnected = false;
        _currentSessionId = null;
        _notifyStateChanges();
        return true;
      } else {
        print('[AI_CHATBOT] Failed to end AI chat');
        return false;
      }
    } catch (e) {
      print('[AI_CHATBOT] Error ending AI chat: $e');
      return false;
    }
  }
}
