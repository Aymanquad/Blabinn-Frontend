import 'dart:async';
import '../../models/message.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import 'socket_types.dart';

class SocketEventHandlers {
  // Handle Socket.IO events
  void handleSocketEvent(
    String event,
    dynamic data,
    StreamController<SocketEvent> eventController,
    StreamController<Message> messageController,
    StreamController<Chat> chatController,
    StreamController<User> userController,
    StreamController<String> typingController,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<String> errorController,
    Function(Map<String, dynamic>) handleIncomingMessage,
    Function(Map<String, dynamic>) handleNewMessageEvent,
    Function(dynamic) handleMessageSentEvent,
    Function(dynamic) handleUserOnlineEvent,
    Function(dynamic) handleUserOfflineEvent,
    Function(dynamic) handleNewChatEvent,
    Function(dynamic) handleChatUpdatedEvent,
    Function(Map<String, dynamic>) handleMatchFoundEvent,
    Function(Map<String, dynamic>) handleRandomChatEvent,
    Function(Map<String, dynamic>) handleRandomChatTimeoutEvent,
    Function(dynamic) handleJoinedEvent,
    Function(dynamic) handleChatJoinedEvent,
    Function(dynamic) handleRandomChatSessionEndedEvent,
    Function(dynamic) handleRandomChatEventReceived,
  ) {
    try {
      print('📡 [SOCKET EVENT DEBUG] Received event: $event with data: $data');
      
      // Add null safety check
      if (data != null && data is! Map<String, dynamic> && data is! List) {
        // Convert to safe format if possible
        if (data is String) {
          data = {'message': data};
        } else {
          data = {'data': data.toString()};
        }
      }

      switch (event) {
        case 'message':
          handleIncomingMessage(data);
          break;
        case 'typing':
          _handleTypingEvent(data, eventController);
          break;
        case 'stop_typing':
          _handleStopTypingEvent(data, eventController);
          break;
        case 'user_online':
          handleUserOnlineEvent(data);
          break;
        case 'user_offline':
          handleUserOfflineEvent(data);
          break;
        case 'message_read':
          _handleMessageReadEvent(data, eventController);
          break;
        case 'new_chat':
          handleNewChatEvent(data);
          break;
        case 'chat_updated':
          handleChatUpdatedEvent(data);
          break;
        case 'user_joined':
          _handleUserJoinedEvent(data, eventController);
          break;
        case 'user_left':
          _handleUserLeftEvent(data, eventController);
          break;
        case 'pong':
          // Handle ping-pong for connection health
          break;
        case 'error':
          _handleServerError(data, errorController, eventController);
          break;
        case 'match_found':
          handleMatchFoundEvent(data);
          break;
        case 'match_accepted':
          _handleMatchAcceptedEvent(data, matchController, eventController);
          break;
        case 'match_rejected':
          _handleMatchRejectedEvent(data, matchController, eventController);
          break;
        case 'random_connection_started':
          _handleRandomConnectionStartedEvent(
              data, matchController, eventController);
          break;
        case 'random_connection_stopped':
          _handleRandomConnectionStoppedEvent(
              data, matchController, eventController);
          break;
        case 'random_chat_event':
          handleRandomChatEvent(data);
          break;
        case 'random_chat_timeout':
          handleRandomChatTimeoutEvent(data);
          break;
        case 'joined':
          handleJoinedEvent(data);
          break;
        case 'new_message':
          handleNewMessageEvent(data);
          break;
        case 'message_sent':
          handleMessageSentEvent(data);
          break;
        case 'chat_joined':
          handleChatJoinedEvent(data);
          break;
        case 'random_chat_session_ended':
          handleRandomChatSessionEndedEvent(data);
          break;
        default:
        // Unknown socket event
      }
    } catch (e) {
      // Error handling
    }
  }

  // Handle typing event
  void _handleTypingEvent(Map<String, dynamic> data,
      StreamController<SocketEvent> eventController) {
    eventController.add(SocketEvent.typing);
  }

  // Handle stop typing event
  void _handleStopTypingEvent(Map<String, dynamic> data,
      StreamController<SocketEvent> eventController) {
    eventController.add(SocketEvent.stopTyping);
  }

  // Handle message read event
  void _handleMessageReadEvent(Map<String, dynamic> data,
      StreamController<SocketEvent> eventController) {
    eventController.add(SocketEvent.messageRead);
  }

  // Handle user joined event
  void _handleUserJoinedEvent(Map<String, dynamic> data,
      StreamController<SocketEvent> eventController) {
    eventController.add(SocketEvent.userJoined);
  }

  // Handle user left event
  void _handleUserLeftEvent(Map<String, dynamic> data,
      StreamController<SocketEvent> eventController) {
    eventController.add(SocketEvent.userLeft);
  }

  // Handle server error
  void _handleServerError(
    dynamic data,
    StreamController<String> errorController,
    StreamController<SocketEvent> eventController,
  ) {
    String error;
    Map<String, dynamic>? errorData;

    if (data == null) {
      error = 'Unknown server error (null data)';
    } else if (data is Map<String, dynamic>) {
      errorData = data;
      error = data['message'] ?? 'Unknown server error';
    } else if (data is String) {
      error = data;
    } else {
      error = 'Server error: ${data.toString()}';
    }

    // Add structured error data if available
    if (errorData != null) {
      errorController.add(
          '$error|${errorData['code'] ?? ''}|${errorData['sessionId'] ?? ''}|${errorData['chatRoomId'] ?? ''}');
    } else {
      errorController.add(error);
    }
    eventController.add(SocketEvent.error);
  }

  // Handle match accepted event
  void _handleMatchAcceptedEvent(
    Map<String, dynamic> data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    matchController.add(data);
    eventController.add(SocketEvent.matchAccepted);
  }

  // Handle match rejected event
  void _handleMatchRejectedEvent(
    Map<String, dynamic> data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    matchController.add(data);
    eventController.add(SocketEvent.matchRejected);
  }

  // Handle random connection started event
  void _handleRandomConnectionStartedEvent(
    dynamic data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    if (data == null) {
      return;
    }

    Map<String, dynamic> eventData;
    if (data is Map<String, dynamic>) {
      eventData = data;
    } else {
      eventData = {'status': 'started', 'data': data.toString()};
    }

    matchController.add(eventData);
    eventController.add(SocketEvent.randomConnectionStarted);
  }

  // Handle random connection stopped event
  void _handleRandomConnectionStoppedEvent(
    dynamic data,
    StreamController<Map<String, dynamic>> matchController,
    StreamController<SocketEvent> eventController,
  ) {
    if (data == null) {
      return;
    }

    Map<String, dynamic> eventData;
    if (data is Map<String, dynamic>) {
      eventData = data;
    } else {
      eventData = {'status': 'stopped', 'data': data.toString()};
    }

    matchController.add(eventData);
    eventController.add(SocketEvent.randomConnectionStopped);
  }
}
