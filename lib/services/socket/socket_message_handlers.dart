import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import '../../models/message.dart';
import '../notification_service.dart';
import '../api_service.dart';
import 'socket_types.dart';

class SocketMessageHandlers {
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();

  // Message deduplication
  final Set<String> _processedMessageIds = {};

  // Track current chat screen state
  String? _currentChatWithUserId;

  // Set current chat user (called when entering a chat)
  void setCurrentChatUser(String? userId) {
    _currentChatWithUserId = userId;
  }

  // Get current chat user
  String? get currentChatWithUserId => _currentChatWithUserId;

  // Clear current chat user (called when leaving a chat)
  void clearCurrentChatUser() {
    _currentChatWithUserId = null;
  }

  // Handle incoming message
  void handleIncomingMessage(
    Map<String, dynamic> data,
    StreamController<Message> messageController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      final message = Message.fromJson(data);
      messageController.add(message);
      eventController.add(SocketEvent.message);

      // Handle image messages through background service
      _handleImageMessageGlobally(message, data);
    } catch (e) {
      // Error handling
    }
  }

  // Show notification for received message
  void showNotificationForMessage(
    Message message,
    Map<String, dynamic> data,
  ) async {
    try {
      final senderId = message.senderId;
      final currentUserId = _getCurrentUserId();

      // Don't show notification if this is our own message
      if (senderId == currentUserId) {
        return;
      }

      // Don't show notification if we're currently in a chat with this sender
      if (_currentChatWithUserId == senderId) {
        return;
      }

      // Get sender information from multiple possible locations in the data
      String senderName = 'Unknown';

      // Try different data structures to find sender name
      if (data['sender'] != null && data['sender'] is Map) {
        final senderData = data['sender'] as Map<String, dynamic>;
        senderName = (senderData['displayName'] as String?) ??
            (senderData['username'] as String?) ??
            senderName;
      } else if (data['message'] != null && data['message'] is Map) {
        final messageData = data['message'] as Map<String, dynamic>;
        if (messageData['sender'] != null && messageData['sender'] is Map) {
          final senderData = messageData['sender'] as Map<String, dynamic>;
          senderName = (senderData['displayName'] as String?) ??
              (senderData['username'] as String?) ??
              senderName;
        }
      } else if (data['senderName'] != null) {
        senderName = data['senderName'] as String;
      }

      // Try to get the correct sender name from the profile API
      try {
        final profileData = await _apiService.getUserProfile(senderId);
        if (profileData['displayName'] != null &&
            profileData['displayName'].toString().isNotEmpty) {
          senderName = profileData['displayName'] as String;
        } else if (profileData['username'] != null &&
            profileData['username'].toString().isNotEmpty) {
          senderName = profileData['username'] as String;
        }
      } catch (e) {
        // Keep the senderName from socket data as fallback
      }

      // Check if app is in foreground - only show in-app notification if app is active
      // Backend push notifications handle background notifications
      if (_notificationService.isAppInForeground) {
        // Disabled socket notification when app is in foreground
        // Firebase push notifications will handle the notification instead
      } else {
        // App in background - backend push notification will handle this
      }
    } catch (e) {
      // Error handling
    }
  }

  // Handle image messages globally for auto-save
  void _handleImageMessageGlobally(Message message, Map<String, dynamic> data) {
    // No-op: Image saving now handled when user opens chat screen.
    // (See ChatScreen logic for conditional save)
  }

  // Get current user ID (helper method)
  String? _getCurrentUserId() {
    try {
      return FirebaseAuth.FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  // Handle new message event
  void handleNewMessageEvent(
    Map<String, dynamic> data,
    StreamController<Message> messageController,
    StreamController<SocketEvent> eventController,
  ) {
    try {
      print('🎯 [NEW MESSAGE EVENT] Received data: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');
      
      // Extract message from nested data structure
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) {
        print('❌ [NEW MESSAGE EVENT] No message data found in payload');
        return;
      }

      print('📦 [NEW MESSAGE EVENT] Message data: $messageData');
      print('👤 [NEW MESSAGE EVENT] Sender ID: ${messageData['senderId']}');
      print('💬 [NEW MESSAGE EVENT] Content: ${messageData['content']}');
      
      final message = Message.fromJson(messageData);
      print('✅ [NEW MESSAGE EVENT] Message parsed successfully: ${message.id}');
      final senderId = message.senderId;
      final currentUserId = _getCurrentUserId();

      // Don't show notification if this is our own message
      if (senderId == currentUserId) {
        print('📤 [NEW MESSAGE EVENT] Own message, adding to stream without notification');
        messageController.add(message);
        return;
      }

      // Don't show notification if we're currently in a chat with this sender
      if (_currentChatWithUserId == senderId) {
        print('💬 [NEW MESSAGE EVENT] Message from current chat partner ($senderId), adding to stream');
        messageController.add(message);
        return;
      }

      // Add message to stream
      print('📨 [NEW MESSAGE EVENT] Adding message to stream from $senderId');
      messageController.add(message);

      // Get sender name for notification (unused in current implementation)
      // String senderName = 'Someone';
      // try {
      //   // Check if sender data is available in the event
      //   if (data.containsKey('sender') && data['sender'] != null) {
      //     final senderData = data['sender'] as Map<String, dynamic>;
      //     if (senderData.containsKey('displayName') &&
      //         senderData['displayName'] != null) {
      //       senderName = senderData['displayName'] as String;
      //     }
      //   }
      //   // Fallback to direct senderName if available
      //   else if (data.containsKey('senderName') && data['senderName'] != null) {
      //     senderName = data['senderName'] as String;
      //   }
      // } catch (e) {
      //   // Error handling
      // }

      // Check if app is in foreground - only show in-app notification if app is active
      // Backend push notifications handle background notifications
      if (_notificationService.isAppInForeground) {
        // Disabled socket notification when app is in foreground
        // Firebase push notifications will handle the notification instead
      } else {
        // App in background - backend push notification will handle this
      }
    } catch (e) {
      // Error handling
    }
  }

  // Handle message sent event
  void handleMessageSentEvent(
    dynamic data,
    StreamController<Message> messageController,
    StreamController<SocketEvent> eventController,
  ) async {
    try {
      if (data == null) {
        return;
      }

      if (data is! Map<String, dynamic>) {
        return;
      }

      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData == null) {
        return;
      }

      final message = Message.fromJson(messageData);

      // Check if we've already processed this message
      if (_processedMessageIds.contains(message.id)) {
        return;
      }

      // Get current user ID to confirm this is from the current user
      final currentUser = await _getCurrentUser();
      final currentUserId = currentUser?['uid'];

      // Only add message if it's from the current user (confirmation)
      if (currentUserId != null && message.senderId == currentUserId) {
        _processedMessageIds.add(message.id);
        messageController.add(message);
        eventController.add(SocketEvent.message);
      }
    } catch (e) {
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
}
