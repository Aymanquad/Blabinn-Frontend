import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../screens/media_folder_screen.dart';
import 'api_service.dart';

class BackgroundImageService {
  static final BackgroundImageService _instance = BackgroundImageService._internal();
  factory BackgroundImageService() => _instance;
  BackgroundImageService._internal();

  final ApiService _apiService = ApiService();
  
  // Queue to handle multiple image downloads
  final List<Map<String, dynamic>> _imageQueue = [];
  bool _isProcessing = false;
  
  /// Main method to handle received image messages from any context
  Future<void> handleReceivedImageMessage(Message message, {String? senderName}) async {
    try {
      print('🖼️ [BACKGROUND IMAGE SERVICE] handleReceivedImageMessage called');
      print('   📦 Message ID: ${message.id}');
      print('   🔗 Image URL: ${message.imageUrl}');
      print('   👤 Sender ID: ${message.senderId}');
      print('   👤 Sender Name: $senderName');
      print('   📱 Message Type: ${message.type}');
      
      // Validate that this is an image message
      if (message.type != MessageType.image || message.imageUrl == null || message.imageUrl!.isEmpty) {
        print('❌ [BACKGROUND IMAGE SERVICE] Not a valid image message');
        return;
      }
      
      // Get current user ID to ensure this is not our own message
      final currentUserId = await _apiService.getCurrentUserId();
      if (currentUserId == null) {
        print('❌ [BACKGROUND IMAGE SERVICE] Current user ID not available');
        return;
      }
      
      // Skip if this is our own message
      if (message.senderId == currentUserId) {
        print('⏭️ [BACKGROUND IMAGE SERVICE] Skipping own message');
        return;
      }
      
      // Get sender information if not provided
      String friendName = senderName ?? 'Unknown Friend';
      if (senderName == null) {
        try {
          final friendProfile = await _apiService.getUserProfile(message.senderId);
          friendName = friendProfile['firstName'] ?? friendProfile['displayName'] ?? 'Unknown Friend';
          print('✅ [BACKGROUND IMAGE SERVICE] Retrieved friend name: $friendName');
        } catch (e) {
          print('⚠️ [BACKGROUND IMAGE SERVICE] Could not get friend name: $e');
          friendName = 'Friend ${message.senderId.substring(0, 8)}';
        }
      }
      
      // Add to processing queue
      _imageQueue.add({
        'message': message,
        'senderName': friendName,
        'timestamp': DateTime.now(),
      });
      
      print('✅ [BACKGROUND IMAGE SERVICE] Added image to processing queue');
      
      // Process queue if not already processing
      _processImageQueue();
      
    } catch (e) {
      print('❌ [BACKGROUND IMAGE SERVICE] Error handling image message: $e');
    }
  }
  
  /// Process the image download queue
  Future<void> _processImageQueue() async {
    if (_isProcessing || _imageQueue.isEmpty) {
      return;
    }
    
    _isProcessing = true;
    print('🔄 [BACKGROUND IMAGE SERVICE] Processing image queue (${_imageQueue.length} items)');
    
    try {
      while (_imageQueue.isNotEmpty) {
        final imageData = _imageQueue.removeAt(0);
        await _downloadAndSaveImage(
          imageData['message'] as Message,
          imageData['senderName'] as String,
        );
        
        // Small delay to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ [BACKGROUND IMAGE SERVICE] Error processing queue: $e');
    } finally {
      _isProcessing = false;
      print('✅ [BACKGROUND IMAGE SERVICE] Finished processing image queue');
    }
  }
  
  /// Download and save image to media folder
  Future<void> _downloadAndSaveImage(Message message, String senderName) async {
    try {
      print('📥 [BACKGROUND IMAGE SERVICE] Downloading image from: ${message.imageUrl}');
      
      // Download image
      final response = await http.get(Uri.parse(message.imageUrl!));
      if (response.statusCode != 200) {
        print('❌ [BACKGROUND IMAGE SERVICE] Failed to download image: ${response.statusCode}');
        return;
      }
      
      print('✅ [BACKGROUND IMAGE SERVICE] Image downloaded, size: ${response.bodyBytes.length} bytes');
      
      // Create temporary file
      final directory = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${directory.path}/temp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      
      final tempFileName = '${DateTime.now().millisecondsSinceEpoch}_received.jpg';
      final tempFile = File('${tempDir.path}/$tempFileName');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      print('✅ [BACKGROUND IMAGE SERVICE] Temporary file created: ${tempFile.path}');
      
      // Save to media folder using MediaFolderScreen method
      await MediaFolderScreen.saveReceivedImage(
        tempFile, 
        message.senderId, 
        senderName,
      );
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      print('✅ [BACKGROUND IMAGE SERVICE] Image saved to media folder successfully');
      
      // Note: Notification handling moved to avoid circular dependency
      // Notifications are now handled by the calling service (SocketService/NotificationService)
      
    } catch (e) {
      print('❌ [BACKGROUND IMAGE SERVICE] Error downloading/saving image: $e');
    }
  }
  

  
  /// Handle image message from push notification data
  Future<void> handleImageFromPushNotification(Map<String, dynamic> notificationData) async {
    try {
      print('🔔 [BACKGROUND IMAGE SERVICE] Handling image from push notification');
      print('   📦 Notification data: $notificationData');
      
      final imageUrl = notificationData['imageUrl'] as String?;
      final senderId = notificationData['senderId'] as String?;
      final senderName = notificationData['senderName'] as String?;
      
      if (imageUrl == null || senderId == null) {
        print('❌ [BACKGROUND IMAGE SERVICE] Missing required data in push notification');
        return;
      }
      
      // Create a message object from notification data
      final message = Message(
        id: notificationData['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: notificationData['chatId'] ?? '',
        senderId: senderId,
        receiverId: await _apiService.getCurrentUserId() ?? '',
        content: '',
        type: MessageType.image,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );
      
      await handleReceivedImageMessage(message, senderName: senderName);
      
    } catch (e) {
      print('❌ [BACKGROUND IMAGE SERVICE] Error handling push notification image: $e');
    }
  }
  
  /// Get queue status for debugging
  Map<String, dynamic> getQueueStatus() {
    return {
      'queueLength': _imageQueue.length,
      'isProcessing': _isProcessing,
      'queueItems': _imageQueue.map((item) => {
        'messageId': (item['message'] as Message).id,
        'senderName': item['senderName'],
        'timestamp': item['timestamp'].toString(),
      }).toList(),
    };
  }
  
  /// Clear queue (for testing/debugging)
  void clearQueue() {
    _imageQueue.clear();
    _isProcessing = false;
    print('🗑️ [BACKGROUND IMAGE SERVICE] Queue cleared');
  }
} 