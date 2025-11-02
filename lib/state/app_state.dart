import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// Central app state management using granular ValueNotifiers
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // User state
  final ValueNotifier<User?> _currentUser = ValueNotifier<User?>(null);
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _error = ValueNotifier<String?>(null);

  // User profile state
  final ValueNotifier<String?> _profileImage = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _username = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _email = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _bio = ValueNotifier<String?>(null);
  final ValueNotifier<List<String>> _interests = ValueNotifier<List<String>>([]);
  final ValueNotifier<int> _credits = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isPremium = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isOnline = ValueNotifier<bool>(false);

  // Friends and connections state
  final ValueNotifier<List<User>> _friends = ValueNotifier<List<User>>([]);
  final ValueNotifier<List<User>> _blockedUsers = ValueNotifier<List<User>>([]);
  final ValueNotifier<List<User>> _friendRequests = ValueNotifier<List<User>>([]);

  // Chat state
  final ValueNotifier<List<Chat>> _chats = ValueNotifier<List<Chat>>([]);
  final ValueNotifier<Chat?> _currentChat = ValueNotifier<Chat?>(null);
  final ValueNotifier<Map<String, List<Message>>> _messages = ValueNotifier<Map<String, List<Message>>>({});
  final ValueNotifier<int> _totalUnreadCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isTyping = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _typingUser = ValueNotifier<String?>(null);

  // Matching state
  final ValueNotifier<bool> _isMatching = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _currentSessionId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _matchMessage = ValueNotifier<String?>(null);
  final ValueNotifier<int> _queueTime = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>> _filters = ValueNotifier<Map<String, dynamic>>({});

  // UI state
  final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isDrawerOpen = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _searchQuery = ValueNotifier<String?>(null);

  // Getters for user state
  ValueNotifier<User?> get currentUser => _currentUser;
  ValueNotifier<bool> get isAuthenticated => _isAuthenticated;
  ValueNotifier<bool> get isLoading => _isLoading;
  ValueNotifier<String?> get error => _error;

  // Getters for user profile state
  ValueNotifier<String?> get profileImage => _profileImage;
  ValueNotifier<String?> get username => _username;
  ValueNotifier<String?> get email => _email;
  ValueNotifier<String?> get bio => _bio;
  ValueNotifier<List<String>> get interests => _interests;
  ValueNotifier<int> get credits => _credits;
  ValueNotifier<bool> get isPremium => _isPremium;
  ValueNotifier<bool> get isOnline => _isOnline;

  // Getters for friends and connections state
  ValueNotifier<List<User>> get friends => _friends;
  ValueNotifier<List<User>> get blockedUsers => _blockedUsers;
  ValueNotifier<List<User>> get friendRequests => _friendRequests;

  // Getters for chat state
  ValueNotifier<List<Chat>> get chats => _chats;
  ValueNotifier<Chat?> get currentChat => _currentChat;
  ValueNotifier<Map<String, List<Message>>> get messages => _messages;
  ValueNotifier<int> get totalUnreadCount => _totalUnreadCount;
  ValueNotifier<bool> get isTyping => _isTyping;
  ValueNotifier<String?> get typingUser => _typingUser;

  // Getters for matching state
  ValueNotifier<bool> get isMatching => _isMatching;
  ValueNotifier<bool> get isConnected => _isConnected;
  ValueNotifier<String?> get currentSessionId => _currentSessionId;
  ValueNotifier<String?> get matchMessage => _matchMessage;
  ValueNotifier<int> get queueTime => _queueTime;
  ValueNotifier<Map<String, dynamic>> get filters => _filters;

  // Getters for UI state
  ValueNotifier<int> get currentTabIndex => _currentTabIndex;
  ValueNotifier<bool> get isDrawerOpen => _isDrawerOpen;
  ValueNotifier<String?> get searchQuery => _searchQuery;

  // User state methods
  void setCurrentUser(User? user) {
    _currentUser.value = user;
    if (user != null) {
      _isAuthenticated.value = true;
      _updateUserProfileState(user);
    } else {
      _isAuthenticated.value = false;
      _clearUserProfileState();
    }
  }

  void setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void setError(String? error) {
    _error.value = error;
  }

  void clearError() {
    _error.value = null;
  }

  // User profile state methods
  void updateUserProfile(User user) {
    _currentUser.value = user;
    _updateUserProfileState(user);
  }

  void updateCredits(int credits) {
    _credits.value = credits;
    if (_currentUser.value != null) {
      _currentUser.value = _currentUser.value!.copyWith(credits: credits);
    }
  }

  void updatePremiumStatus(bool isPremium) {
    _isPremium.value = isPremium;
    if (_currentUser.value != null) {
      _currentUser.value = _currentUser.value!.copyWith(isPremium: isPremium);
    }
  }

  void updateOnlineStatus(bool isOnline) {
    _isOnline.value = isOnline;
    if (_currentUser.value != null) {
      _currentUser.value = _currentUser.value!.copyWith(isOnline: isOnline);
    }
  }

  void updateInterests(List<String> interests) {
    _interests.value = interests;
    if (_currentUser.value != null) {
      _currentUser.value = _currentUser.value!.copyWith(interests: interests);
    }
  }

  // Friends and connections state methods
  void setFriends(List<User> friends) {
    _friends.value = friends;
  }

  void addFriend(User friend) {
    final currentFriends = List<User>.from(_friends.value);
    if (!currentFriends.any((f) => f.id == friend.id)) {
      currentFriends.add(friend);
      _friends.value = currentFriends;
    }
  }

  void removeFriend(String friendId) {
    final currentFriends = List<User>.from(_friends.value);
    currentFriends.removeWhere((f) => f.id == friendId);
    _friends.value = currentFriends;
  }

  void setBlockedUsers(List<User> blockedUsers) {
    _blockedUsers.value = blockedUsers;
  }

  void addBlockedUser(User user) {
    final currentBlocked = List<User>.from(_blockedUsers.value);
    if (!currentBlocked.any((u) => u.id == user.id)) {
      currentBlocked.add(user);
      _blockedUsers.value = currentBlocked;
    }
  }

  void removeBlockedUser(String userId) {
    final currentBlocked = List<User>.from(_blockedUsers.value);
    currentBlocked.removeWhere((u) => u.id == userId);
    _blockedUsers.value = currentBlocked;
  }

  void setFriendRequests(List<User> requests) {
    _friendRequests.value = requests;
  }

  void addFriendRequest(User user) {
    final currentRequests = List<User>.from(_friendRequests.value);
    if (!currentRequests.any((r) => r.id == user.id)) {
      currentRequests.add(user);
      _friendRequests.value = currentRequests;
    }
  }

  void removeFriendRequest(String userId) {
    final currentRequests = List<User>.from(_friendRequests.value);
    currentRequests.removeWhere((r) => r.id == userId);
    _friendRequests.value = currentRequests;
  }

  // Chat state methods
  void setChats(List<Chat> chats) {
    _chats.value = chats;
    _updateTotalUnreadCount();
  }

  void addChat(Chat chat) {
    final currentChats = List<Chat>.from(_chats.value);
    if (!currentChats.any((c) => c.id == chat.id)) {
      currentChats.add(chat);
      _chats.value = currentChats;
      _updateTotalUnreadCount();
    }
  }

  void updateChat(Chat chat) {
    final currentChats = List<Chat>.from(_chats.value);
    final index = currentChats.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      currentChats[index] = chat;
      _chats.value = currentChats;
      _updateTotalUnreadCount();
    }
  }

  void removeChat(String chatId) {
    final currentChats = List<Chat>.from(_chats.value);
    currentChats.removeWhere((c) => c.id == chatId);
    _chats.value = currentChats;
    _updateTotalUnreadCount();
  }

  void setCurrentChat(Chat? chat) {
    _currentChat.value = chat;
  }

  void setMessages(String chatId, List<Message> messages) {
    final currentMessages = Map<String, List<Message>>.from(_messages.value);
    currentMessages[chatId] = messages;
    _messages.value = currentMessages;
  }

  void addMessage(String chatId, Message message) {
    final currentMessages = Map<String, List<Message>>.from(_messages.value);
    if (!currentMessages.containsKey(chatId)) {
      currentMessages[chatId] = [];
    }
    currentMessages[chatId]!.add(message);
    _messages.value = currentMessages;
  }

  void setTypingStatus(bool isTyping, {String? user}) {
    _isTyping.value = isTyping;
    _typingUser.value = user;
  }

  // Matching state methods
  void setMatching(bool isMatching) {
    _isMatching.value = isMatching;
  }

  void setConnected(bool isConnected) {
    _isConnected.value = isConnected;
  }

  void setCurrentSessionId(String? sessionId) {
    _currentSessionId.value = sessionId;
  }

  void setMatchMessage(String? message) {
    _matchMessage.value = message;
  }

  void setQueueTime(int time) {
    _queueTime.value = time;
  }

  void setFilters(Map<String, dynamic> filters) {
    _filters.value = filters;
  }

  // UI state methods
  void setCurrentTabIndex(int index) {
    _currentTabIndex.value = index;
  }

  void setDrawerOpen(bool isOpen) {
    _isDrawerOpen.value = isOpen;
  }

  void setSearchQuery(String? query) {
    _searchQuery.value = query;
  }

  // Helper methods
  void _updateUserProfileState(User user) {
    _profileImage.value = user.profileImage;
    _username.value = user.username;
    _email.value = user.email;
    _bio.value = user.bio;
    _interests.value = user.interests;
    _credits.value = user.credits;
    _isPremium.value = user.isPremium;
    _isOnline.value = user.isOnline;
  }

  void _clearUserProfileState() {
    _profileImage.value = null;
    _username.value = null;
    _email.value = null;
    _bio.value = null;
    _interests.value = [];
    _credits.value = 0;
    _isPremium.value = false;
    _isOnline.value = false;
  }

  void _updateTotalUnreadCount() {
    final total = _chats.value.fold(0, (sum, chat) => sum + chat.unreadCount);
    _totalUnreadCount.value = total;
  }

  // Clear all state
  void clearAllState() {
    setCurrentUser(null);
    setFriends([]);
    setBlockedUsers([]);
    setFriendRequests([]);
    setChats([]);
    setCurrentChat(null);
    _messages.value = {};
    setMatching(false);
    setConnected(false);
    setCurrentSessionId(null);
    setMatchMessage(null);
    setQueueTime(0);
    setFilters({});
    setCurrentTabIndex(0);
    setDrawerOpen(false);
    setSearchQuery(null);
    clearError();
  }

  // Dispose all notifiers
  void dispose() {
    _currentUser.dispose();
    _isAuthenticated.dispose();
    _isLoading.dispose();
    _error.dispose();
    _profileImage.dispose();
    _username.dispose();
    _email.dispose();
    _bio.dispose();
    _interests.dispose();
    _credits.dispose();
    _isPremium.dispose();
    _isOnline.dispose();
    _friends.dispose();
    _blockedUsers.dispose();
    _friendRequests.dispose();
    _chats.dispose();
    _currentChat.dispose();
    _messages.dispose();
    _totalUnreadCount.dispose();
    _isTyping.dispose();
    _typingUser.dispose();
    _isMatching.dispose();
    _isConnected.dispose();
    _currentSessionId.dispose();
    _matchMessage.dispose();
    _queueTime.dispose();
    _filters.dispose();
    _currentTabIndex.dispose();
    _isDrawerOpen.dispose();
    _searchQuery.dispose();
  }
}
