import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  Chat? _currentChat;
  bool _isLoading = false;
  String? _error;
  bool _isTyping = false;
  String? _typingUser;

  // Getters
  List<Chat> get chats => _chats;
  Map<String, List<Message>> get messages => _messages;
  Chat? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTyping => _isTyping;
  String? get typingUser => _typingUser;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadChats();
      _setupSocketListeners();
    } catch (e) {
      _setError('Failed to initialize chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Setup socket listeners
  void _setupSocketListeners() {
    _socketService.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });

    _socketService.userStatusStream.listen((user) {
      _handleUserStatusUpdate(user);
    });

    _socketService.matchStream.listen((matchData) {
      _handleMatchUpdate(matchData);
    });
  }

  // Load chats
  Future<void> loadChats() async {
    _setLoading(true);
    try {
      _chats = await _apiService.getChats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load messages for a specific chat
  Future<void> loadMessages(String chatId, {int? limit, int? offset}) async {
    try {
      final messages = await _apiService.getChatMessages(chatId, limit: limit, offset: offset);
      _messages[chatId] = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    }
  }

  // Set current chat
  void setCurrentChat(Chat chat) {
    _currentChat = chat;
    if (!_messages.containsKey(chat.id)) {
      loadMessages(chat.id);
    }
    notifyListeners();
  }

  // Send message
  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text}) async {
    try {
      final message = await _apiService.sendMessage(chatId, content, type: type);
      
      // Add message to local state
      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(message);
      
      // Update chat's last message
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          lastMessage: message,
          lastMessageAt: message.timestamp,
          unreadCount: 0,
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to send message: $e');
    }
  }

  // Send message through socket
  Future<void> sendMessageViaSocket(String chatId, String content, {MessageType type = MessageType.text}) async {
    try {
      await _socketService.sendMessage(chatId, content, type: type);
    } catch (e) {
      _setError('Failed to send message via socket: $e');
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String chatId) async {
    try {
      await _socketService.sendTyping(chatId);
    } catch (e) {
      // Ignore typing indicator errors
    }
  }

  // Send stop typing indicator
  Future<void> sendStopTypingIndicator(String chatId) async {
    try {
      await _socketService.sendStopTyping(chatId);
    } catch (e) {
      // Ignore typing indicator errors
    }
  }

  // Join chat room
  Future<void> joinChat(String chatId) async {
    try {
      await _socketService.joinChat(chatId);
    } catch (e) {
      _setError('Failed to join chat: $e');
    }
  }

  // Leave chat room
  Future<void> leaveChat(String chatId) async {
    try {
      await _socketService.leaveChat(chatId);
    } catch (e) {
      _setError('Failed to leave chat: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _apiService.markMessagesAsRead(chatId);
      
      // Update local state
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark messages as read: $e');
    }
  }

  // End chat
  Future<void> endChat(String chatId, {String? reason}) async {
    try {
      await _apiService.endChat(chatId, reason: reason);
      
      // Update local state
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          status: ChatStatus.ended,
          endedAt: DateTime.now(),
          reason: reason,
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to end chat: $e');
    }
  }

  // Handle incoming message
  void _handleIncomingMessage(Message message) {
    final chatId = message.chatId;
    
    // Add message to local state
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }
    _messages[chatId]!.add(message);
    
    // Update chat's last message
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final currentChat = _chats[chatIndex];
      _chats[chatIndex] = currentChat.copyWith(
        lastMessage: message,
        lastMessageAt: message.timestamp,
        unreadCount: currentChat.unreadCount + 1,
      );
    } else {
      // Create new chat if it doesn't exist
      final newChat = Chat(
        id: chatId,
        participant1Id: message.senderId,
        participant2Id: message.receiverId,
        type: ChatType.random,
        status: ChatStatus.active,
        createdAt: DateTime.now(),
        lastMessage: message,
        lastMessageAt: message.timestamp,
        unreadCount: 1,
      );
      _chats.add(newChat);
    }
    
    notifyListeners();
  }

  // Handle user status update
  void _handleUserStatusUpdate(User user) {
    // Update user status in chats
    for (int i = 0; i < _chats.length; i++) {
      final chat = _chats[i];
      if (chat.participant1Id == user.id || chat.participant2Id == user.id) {
        // Update chat with user status
        // This would require storing user data in chat or having a separate user provider
      }
    }
    notifyListeners();
  }

  // Handle match update
  void _handleMatchUpdate(Map<String, dynamic> matchData) {
    // Handle match found/ended events
    final event = matchData['event'];
    final chatId = matchData['chatId'];
    
    switch (event) {
      case 'match_found':
        // Create new chat for the match
        final newChat = Chat(
          id: chatId,
          participant1Id: matchData['participant1Id'],
          participant2Id: matchData['participant2Id'],
          type: ChatType.random,
          status: ChatStatus.active,
          createdAt: DateTime.now(),
        );
        _chats.add(newChat);
        break;
      case 'match_ended':
        // Update chat status
        final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
        if (chatIndex != -1) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(
            status: ChatStatus.ended,
            endedAt: DateTime.now(),
          );
        }
        break;
    }
    
    notifyListeners();
  }

  // Get messages for a specific chat
  List<Message> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  // Get unread count for a specific chat
  int getUnreadCount(String chatId) {
    final chat = _chats.firstWhere(
      (chat) => chat.id == chatId,
      orElse: () => Chat(
        id: chatId,
        participant1Id: '',
        participant2Id: '',
        type: ChatType.random,
        status: ChatStatus.active,
        createdAt: DateTime.now(),
      ),
    );
    return chat.unreadCount;
  }

  // Get total unread count
  int get totalUnreadCount {
    return _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  // Get chat by ID
  Chat? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Get other participant ID
  String? getOtherParticipantId(String chatId, String currentUserId) {
    final chat = getChatById(chatId);
    if (chat != null) {
      return chat.getOtherParticipantId(currentUserId);
    }
    return null;
  }

  // Check if chat is active
  bool isChatActive(String chatId) {
    final chat = getChatById(chatId);
    return chat?.status == ChatStatus.active;
  }

  // Check if chat is ended
  bool isChatEnded(String chatId) {
    final chat = getChatById(chatId);
    return chat?.status == ChatStatus.ended;
  }

  // Check if chat is blocked
  bool isChatBlocked(String chatId) {
    final chat = getChatById(chatId);
    return chat?.status == ChatStatus.blocked;
  }

  // Check if chat is reported
  bool isChatReported(String chatId) {
    final chat = getChatById(chatId);
    return chat?.status == ChatStatus.reported;
  }

  // Set typing status
  void setTypingStatus(bool isTyping, {String? user}) {
    _isTyping = isTyping;
    _typingUser = user;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _chats.clear();
    _messages.clear();
    _currentChat = null;
    _error = null;
    _isTyping = false;
    _typingUser = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
} 