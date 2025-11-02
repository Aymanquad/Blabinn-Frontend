import 'dart:async';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../models/chat.dart';
import 'socket_types.dart';

class SocketRandomChatHandlers {
  // Store latest random chat event data for immediate access
  Map<String, dynamic>? _latestRandomChatData;
  Map<String, dynamic>? _latestTimeoutData;

  // Get the latest random chat event data
  Map<String, dynamic>? get latestRandomChatData => _latestRandomChatData;

  // Store the latest timeout data for UI access
  Map<String, dynamic>? get latestTimeoutData => _latestTimeoutData;

  // Handle match found event
  void handleMatchFoundEvent(
    Map<String, dynamic> data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    // Extract match information
    final matchType = data['matchType'] ?? 'unknown';
    final interestSimilarity = data['interestSimilarity'] ?? 0.0;
    final user1 = data['user1'];
    final user2 = data['user2'];
    final user1Interests = data['user1Interests'] ?? [];
    final user2Interests = data['user2Interests'] ?? [];

    // Show common interests
    if (user1Interests is List && user2Interests is List) {
      final commonInterests = user1Interests
          .where((interest) => user2Interests.any((otherInterest) =>
              interest.toString().toLowerCase() ==
              otherInterest.toString().toLowerCase()))
          .toList();
    }

    matchController.add(data);
    eventController.add(SocketEvent.matchFound);
  }

  // Handle random chat event
  void handleRandomChatEvent(
    dynamic data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
    Function(String) joinChat,
  ) {
    print('🎯 [RANDOM CHAT EVENT DEBUG] Received random chat event: $data');

    // Extract and display match analytics if available
    if (data is Map<String, dynamic>) {
      final matchType = data['matchType'];
      final interestSimilarity = data['interestSimilarity'];
      final user1Interests = data['user1Interests'];
      final user2Interests = data['user2Interests'];

      if (matchType != null) {
        if (interestSimilarity != null) {
          // Interest similarity logging
        }
        if (user1Interests != null && user2Interests != null) {
          // User interests logging
        }
      }
    }

    // Null safety check
    if (data == null) {
      return;
    }

    Map<String, dynamic> eventData;
    if (data is Map<String, dynamic>) {
      eventData = data;
    } else if (data is String) {
      // Try to parse as JSON if it's a string
      try {
        eventData = {'message': data};
      } catch (e) {
        return;
      }
    } else {
      return;
    }

    // Check for specific event types
    final eventType = eventData['event'];
    print('🎯 [RANDOM CHAT EVENT DEBUG] Event type: $eventType');
    if (eventType == 'session_ended') {
      // Handle session ended event specifically
      print('🚪 [RANDOM CHAT EVENT DEBUG] Session ended event detected');
      eventController.add(SocketEvent.randomChatSessionEnded);
      return;
    }

    // Automatically join the chat room when random chat event is received
    if (eventData['chatRoomId'] != null) {
      joinChat(eventData['chatRoomId']);
    }

    // Store the latest random chat event data
    _latestRandomChatData = eventData;
    matchController.add(eventData);
    eventController.add(SocketEvent.randomChatEvent);
  }

  // Handle random chat timeout event
  void handleRandomChatTimeoutEvent(
    Map<String, dynamic> data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    // Extract timeout information
    final String reason = data['reason'] ?? 'time_limit_exceeded';
    final String genderPreference = data['genderPreference'] ?? 'any';
    final String message =
        data['message'] ?? 'No match found. Please try again later.';

    // Add enhanced timeout data
    final timeoutData = {
      ...data,
      'reason': reason,
      'genderPreference': genderPreference,
      'message': message,
    };

    // Store timeout data for UI access
    _latestTimeoutData = timeoutData;

    matchController.add(timeoutData);
    eventController.add(SocketEvent.randomChatTimeout);
  }

  // Handle user online event
  void handleUserOnlineEvent(
    dynamic data,
    StreamController<User> userController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      if (data == null) {
        return;
      }

      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        // Check if data has 'user' nested object or direct user data
        if (data.containsKey('user') && data['user'] != null) {
          userData = data['user'];
        } else {
          // Data is direct user data format
          userData = data;
        }
      } else {
        return;
      }

      final user = User.fromJson(userData);
      userController.add(user);
      eventController.add(SocketEvent.userOnline);
    } catch (e) {
      // Error handling
    }
  }

  // Handle user offline event
  void handleUserOfflineEvent(
    dynamic data,
    StreamController<User> userController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      if (data == null) {
        return;
      }

      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        // Check if data has 'user' nested object or direct user data
        if (data.containsKey('user') && data['user'] != null) {
          userData = data['user'];
        } else {
          // Data is direct user data format
          userData = data;
        }
      } else {
        return;
      }

      final user = User.fromJson(userData);
      userController.add(user);
      eventController.add(SocketEvent.userOffline);
    } catch (e) {
      // Error handling
    }
  }

  // Handle new chat event
  void handleNewChatEvent(
    dynamic data,
    StreamController<Chat> chatController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      if (data == null) {
        return;
      }

      if (data is! Map<String, dynamic>) {
        return;
      }

      final chatData = data['chat'];
      if (chatData == null) {
        return;
      }

      final chat = Chat.fromJson(chatData);
      chatController.add(chat);
      eventController.add(SocketEvent.newChat);
    } catch (e) {
      // Error handling
    }
  }

  // Handle chat updated event
  void handleChatUpdatedEvent(
    dynamic data,
    StreamController<Chat> chatController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      if (data == null) {
        return;
      }

      if (data is! Map<String, dynamic>) {
        return;
      }

      final chatData = data['chat'];
      if (chatData == null) {
        return;
      }

      final chat = Chat.fromJson(chatData);
      chatController.add(chat);
      eventController.add(SocketEvent.chatUpdated);
    } catch (e) {
      // Error handling
    }
  }

  // Handle joined event
  void handleJoinedEvent(
    dynamic data,
    StreamController<SocketEvent> eventController,
  ) {
    if (data == null) {
      // Joined event data is null (but this is OK)
    }

    eventController.add(SocketEvent.userJoined);
  }

  // Handle chat joined event
  void handleChatJoinedEvent(
    dynamic data,
    StreamController<SocketEvent> eventController,
  ) {
    eventController.add(SocketEvent.userJoined);
  }

  // Handle random chat session ended event
  void handleRandomChatSessionEndedEvent(
    dynamic data,
    StreamController<SocketEvent> eventController,
  ) {
    print('🚪 [RANDOM CHAT SESSION DEBUG] Session ended event received: $data');

    // Extract session information if available
    if (data is Map<String, dynamic>) {
      final sessionId = data['sessionId'];
      final reason = data['reason'];
      final endedBy = data['endedBy'];

      print(
          '🚪 [RANDOM CHAT SESSION DEBUG] Session ended - ID: $sessionId, Reason: $reason, Ended by: $endedBy');
    }

    eventController.add(SocketEvent.randomChatSessionEnded);
  }

  // Handle random chat event received
  void handleRandomChatEventReceived(
    dynamic data,
    StreamController<SocketEvent> eventController,
  ) {
    eventController.add(SocketEvent.randomChatEvent);
  }
}
