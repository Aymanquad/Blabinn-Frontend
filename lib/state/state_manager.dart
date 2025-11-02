import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';
import 'app_state.dart';

/// State manager that coordinates between services and the granular state system
class StateManager {
  static final StateManager _instance = StateManager._internal();
  factory StateManager() => _instance;
  StateManager._internal();

  final AppState _appState = AppState();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Getters for app state
  AppState get appState => _appState;

  /// Initialize the state manager
  Future<void> initialize() async {
    try {
      Logger.info('Initializing StateManager...');
      
      // Initialize services
      await _authService.initialize();
      await _apiService.initialize();
      await _socketService.initialize();

      // Set up listeners
      _setupAuthListeners();
      _setupSocketListeners();

      // Load initial state
      await _loadInitialState();

      Logger.info('StateManager initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize StateManager', error: e);
      _appState.setError('Failed to initialize app: $e');
    }
  }

  /// Set up authentication listeners
  void _setupAuthListeners() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _appState.setCurrentUser(user);
      if (user != null) {
        _loadUserData();
      } else {
        _appState.clearAllState();
      }
    });
  }

  /// Set up socket listeners
  void _setupSocketListeners() {
    // Listen to socket connection status
    _socketService.connectionStream.listen((isConnected) {
      _appState.setConnected(isConnected);
    });

    // Listen to incoming messages
    _socketService.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });

    // Listen to user status updates
    _socketService.userStatusStream.listen((user) {
      _handleUserStatusUpdate(user);
    });

    // Listen to match updates
    _socketService.matchStream.listen((matchData) {
      _handleMatchUpdate(matchData);
    });

    // Listen to typing indicators
    _socketService.typingStream.listen((typingData) {
      _handleTypingIndicator(typingData);
    });
  }

  /// Load initial state
  Future<void> _loadInitialState() async {
    try {
      _appState.setLoading(true);

      // Load current user if authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _appState.setCurrentUser(currentUser);
        await _loadUserData();
      }

      _appState.setLoading(false);
    } catch (e) {
      Logger.error('Failed to load initial state', error: e);
      _appState.setError('Failed to load initial data: $e');
      _appState.setLoading(false);
    }
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      final user = _appState.currentUser.value;
      if (user == null) return;

      // Load friends
      await _loadFriends();

      // Load blocked users
      await _loadBlockedUsers();

      // Load friend requests
      await _loadFriendRequests();

      // Load chats
      await _loadChats();

      // Sync credits from server
      await _syncCreditsFromServer();

    } catch (e) {
      Logger.error('Failed to load user data', error: e);
    }
  }

  /// Load friends
  Future<void> _loadFriends() async {
    try {
      final friendsData = await _apiService.getFriends();
      final friends = friendsData.map((data) => User.fromJson(data)).toList();
      _appState.setFriends(friends);
    } catch (e) {
      Logger.error('Failed to load friends', error: e);
    }
  }

  /// Load blocked users
  Future<void> _loadBlockedUsers() async {
    try {
      final blockedUsersData = await _apiService.getBlockedUsers();
      final blockedUsers = blockedUsersData.map((data) => User.fromJson(data)).toList();
      _appState.setBlockedUsers(blockedUsers);
    } catch (e) {
      Logger.error('Failed to load blocked users', error: e);
    }
  }

  /// Load friend requests
  Future<void> _loadFriendRequests() async {
    try {
      final requestsData = await _apiService.getIncomingFriendRequests();
      final requests = requestsData.map((data) => User.fromJson(data)).toList();
      _appState.setFriendRequests(requests);
    } catch (e) {
      Logger.error('Failed to load friend requests', error: e);
    }
  }

  /// Load chats
  Future<void> _loadChats() async {
    try {
      final chatsData = await _apiService.getChats();
      final chats = chatsData.map((data) => Chat.fromJson(data)).toList();
      _appState.setChats(chats);
    } catch (e) {
      Logger.error('Failed to load chats', error: e);
    }
  }

  /// Sync credits from server
  Future<void> _syncCreditsFromServer() async {
    try {
      final user = _appState.currentUser.value;
      if (user == null) return;

      final profileData = await _apiService.getMyProfile();
      final serverCredits = (profileData['credits'] as int?) ?? user.credits;
      
      if (user.credits != serverCredits) {
        _appState.updateCredits(serverCredits);
      }
    } catch (e) {
      Logger.error('Failed to sync credits from server', error: e);
    }
  }

  /// Handle incoming message
  void _handleIncomingMessage(Message message) {
    try {
      _appState.addMessage(message.chatId, message);
      
      // Update chat's last message and unread count
      final chats = _appState.chats.value;
      final chatIndex = chats.indexWhere((chat) => chat.id == message.chatId);
      
      if (chatIndex != -1) {
        final chat = chats[chatIndex];
        final updatedChat = chat.copyWith(
          lastMessage: message,
          lastMessageAt: message.timestamp,
          unreadCount: chat.unreadCount + 1,
        );
        _appState.updateChat(updatedChat);
      } else {
        // Create new chat if it doesn't exist
        final newChat = Chat(
          id: message.chatId,
          participant1Id: message.senderId,
          participant2Id: message.receiverId,
          type: ChatType.random,
          status: ChatStatus.active,
          createdAt: DateTime.now(),
          lastMessage: message,
          lastMessageAt: message.timestamp,
          unreadCount: 1,
        );
        _appState.addChat(newChat);
      }
    } catch (e) {
      Logger.error('Failed to handle incoming message', error: e);
    }
  }

  /// Handle user status update
  void _handleUserStatusUpdate(User user) {
    try {
      // Update user in friends list if present
      final friends = _appState.friends.value;
      final friendIndex = friends.indexWhere((f) => f.id == user.id);
      
      if (friendIndex != -1) {
        final updatedFriends = List<User>.from(friends);
        updatedFriends[friendIndex] = user;
        _appState.setFriends(updatedFriends);
      }
    } catch (e) {
      Logger.error('Failed to handle user status update', error: e);
    }
  }

  /// Handle match update
  void _handleMatchUpdate(Map<String, dynamic> matchData) {
    try {
      final event = matchData['event'];
      final chatId = matchData['chatId'];
      
      switch (event) {
        case 'match_found':
          _appState.setMatching(false);
          _appState.setMatchMessage('Match found!');
          
          // Create new chat for the match
          final newChat = Chat(
            id: chatId,
            participant1Id: matchData['participant1Id'],
            participant2Id: matchData['participant2Id'],
            type: ChatType.random,
            status: ChatStatus.active,
            createdAt: DateTime.now(),
          );
          _appState.addChat(newChat);
          break;
          
        case 'match_ended':
          _appState.setMatching(false);
          _appState.setMatchMessage('Match ended');
          
          // Update chat status
          final chats = _appState.chats.value;
          final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
          
          if (chatIndex != -1) {
            final chat = chats[chatIndex];
            final updatedChat = chat.copyWith(
              status: ChatStatus.ended,
              endedAt: DateTime.now(),
            );
            _appState.updateChat(updatedChat);
          }
          break;
      }
    } catch (e) {
      Logger.error('Failed to handle match update', error: e);
    }
  }

  /// Handle typing indicator
  void _handleTypingIndicator(Map<String, dynamic> typingData) {
    try {
      final isTyping = typingData['isTyping'] as bool? ?? false;
      final user = typingData['user'] as String?;
      
      _appState.setTypingStatus(isTyping, user: user);
    } catch (e) {
      Logger.error('Failed to handle typing indicator', error: e);
    }
  }

  /// Authentication methods
  Future<bool> login(String email, String password) async {
    try {
      _appState.setLoading(true);
      _appState.clearError();
      
      final result = await _authService.login(email, password);
      _appState.setCurrentUser(result.user);
      
      return true;
    } catch (e) {
      Logger.error('Login failed', error: e);
      _appState.setError('Login failed: $e');
      return false;
    } finally {
      _appState.setLoading(false);
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      _appState.setLoading(true);
      _appState.clearError();
      
      final result = await _authService.register(username, email, password);
      _appState.setCurrentUser(result.user);
      
      return true;
    } catch (e) {
      Logger.error('Registration failed', error: e);
      _appState.setError('Registration failed: $e');
      return false;
    } finally {
      _appState.setLoading(false);
    }
  }

  Future<bool> loginAsGuest() async {
    try {
      _appState.setLoading(true);
      _appState.clearError();
      
      final result = await _authService.loginAsGuest();
      _appState.setCurrentUser(result.user);
      
      return true;
    } catch (e) {
      Logger.error('Guest login failed', error: e);
      _appState.setError('Guest login failed: $e');
      return false;
    } finally {
      _appState.setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _appState.clearAllState();
    } catch (e) {
      Logger.error('Logout failed', error: e);
      _appState.setError('Logout failed: $e');
    }
  }

  /// Chat methods
  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text}) async {
    try {
      final message = await _apiService.sendMessage(chatId, content, type: type);
      _appState.addMessage(chatId, message);
      
      // Update chat's last message
      final chats = _appState.chats.value;
      final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
      
      if (chatIndex != -1) {
        final chat = chats[chatIndex];
        final updatedChat = chat.copyWith(
          lastMessage: message,
          lastMessageAt: message.timestamp,
          unreadCount: 0,
        );
        _appState.updateChat(updatedChat);
      }
    } catch (e) {
      Logger.error('Failed to send message', error: e);
      _appState.setError('Failed to send message: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _apiService.markMessagesAsRead(chatId);
      
      // Update local state
      final chats = _appState.chats.value;
      final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
      
      if (chatIndex != -1) {
        final chat = chats[chatIndex];
        final updatedChat = chat.copyWith(unreadCount: 0);
        _appState.updateChat(updatedChat);
      }
    } catch (e) {
      Logger.error('Failed to mark messages as read', error: e);
    }
  }

  /// Friend management methods
  Future<bool> sendFriendRequest(String userId, {String? message}) async {
    try {
      await _apiService.sendFriendRequest(userId, message: message);
      return true;
    } catch (e) {
      Logger.error('Failed to send friend request', error: e);
      _appState.setError('Failed to send friend request: $e');
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String connectionId) async {
    try {
      await _apiService.acceptFriendRequest(connectionId);
      await _loadFriends();
      await _loadFriendRequests();
      return true;
    } catch (e) {
      Logger.error('Failed to accept friend request', error: e);
      _appState.setError('Failed to accept friend request: $e');
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String connectionId) async {
    try {
      await _apiService.rejectFriendRequest(connectionId);
      await _loadFriendRequests();
      return true;
    } catch (e) {
      Logger.error('Failed to reject friend request', error: e);
      _appState.setError('Failed to reject friend request: $e');
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      await _apiService.blockUser(userId);
      await _loadBlockedUsers();
      return true;
    } catch (e) {
      Logger.error('Failed to block user', error: e);
      _appState.setError('Failed to block user: $e');
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      await _apiService.unblockUser(userId);
      await _loadBlockedUsers();
      return true;
    } catch (e) {
      Logger.error('Failed to unblock user', error: e);
      _appState.setError('Failed to unblock user: $e');
      return false;
    }
  }

  /// Matching methods
  Future<void> startMatching() async {
    try {
      _appState.setMatching(true);
      _appState.setQueueTime(0);
      
      // Start matching process
      await _socketService.startMatching();
    } catch (e) {
      Logger.error('Failed to start matching', error: e);
      _appState.setMatching(false);
      _appState.setError('Failed to start matching: $e');
    }
  }

  Future<void> stopMatching() async {
    try {
      _appState.setMatching(false);
      await _socketService.stopMatching();
    } catch (e) {
      Logger.error('Failed to stop matching', error: e);
    }
  }

  /// Profile update methods
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      _appState.setLoading(true);
      
      final result = await _authService.updateProfile(data);
      _appState.setCurrentUser(result.user);
      
      return true;
    } catch (e) {
      Logger.error('Failed to update profile', error: e);
      _appState.setError('Failed to update profile: $e');
      return false;
    } finally {
      _appState.setLoading(false);
    }
  }

  /// Credits methods
  Future<void> refreshCredits() async {
    await _syncCreditsFromServer();
  }

  void updateCredits(int credits) {
    _appState.updateCredits(credits);
  }

  /// Dispose
  void dispose() {
    _appState.dispose();
  }
}
