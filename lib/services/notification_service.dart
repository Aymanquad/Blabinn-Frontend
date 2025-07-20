import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  
  final StreamController<Map<String, dynamic>> _inAppNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get inAppNotificationStream =>
      _inAppNotificationController.stream;
  
  bool _isAppInForeground = true; // Start as foreground
  String? _fcmToken;
  
  // Initialize the notification service
  Future<void> initialize() async {
    print('🔔 [NOTIFICATION DEBUG] Initializing notification service...');
    
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      print('✅ [NOTIFICATION DEBUG] Notification service initialized successfully');
    } catch (e) {
      print('❌ [NOTIFICATION DEBUG] Failed to initialize notifications: $e');
    }
  }
  
  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    print('🔔 [NOTIFICATION DEBUG] Setting up local notifications...');
    
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
  
  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    print('🔔 [NOTIFICATION DEBUG] Setting up Firebase messaging...');
    
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('🔔 [NOTIFICATION DEBUG] Permission granted: ${settings.authorizationStatus}');
    
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('🔔 [NOTIFICATION DEBUG] FCM Token: $_fcmToken');
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      print('🔔 [NOTIFICATION DEBUG] FCM Token refreshed: $token');
      _fcmToken = token;
      // TODO: Send updated token to backend
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check for initial message if app was opened from notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  // Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 [NOTIFICATION DEBUG] Foreground message received');
    print('   📦 Title: ${message.notification?.title}');
    print('   📦 Body: ${message.notification?.body}');
    print('   📦 Data: ${message.data}');
    
    if (_isAppInForeground) {
      // Show in-app notification
      _showInAppNotification(message);
    } else {
      // Show local notification
      await _showLocalNotification(message);
    }
  }
  
  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('🔔 [NOTIFICATION DEBUG] Background message received');
    print('   📦 Message ID: ${message.messageId}');
    // Background messages are automatically handled by the system
  }
  
  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('🔔 [NOTIFICATION DEBUG] Notification tapped');
    print('   📦 Data: ${message.data}');
    
    // TODO: Navigate to appropriate screen based on message data
    final chatId = message.data['chatId'];
    final senderId = message.data['senderId'];
    
    if (chatId != null) {
      print('🔔 [NOTIFICATION DEBUG] Should navigate to chat: $chatId');
      // Add navigation logic here
    }
  }
  
  // Show in-app notification (when app is active)
  void _showInAppNotification(RemoteMessage message) {
    final senderName = message.data['senderName'] ?? message.notification?.title ?? 'Unknown';
    final messageContent = message.notification?.body ?? 'New message';
    
    _inAppNotificationController.add({
      'type': 'chat_message',
      'senderName': senderName,
      'message': messageContent,
      'senderId': message.data['senderId'],
      'chatId': message.data['chatId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: message.data['chatId'],
    );
  }
  
  // Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 [NOTIFICATION DEBUG] Local notification tapped');
    print('   📦 Payload: ${response.payload}');
    
    // TODO: Navigate to chat screen
    if (response.payload != null) {
      print('🔔 [NOTIFICATION DEBUG] Should navigate to chat: ${response.payload}');
    }
  }
  
  // Show in-app notification for socket messages
  void showInAppNotificationForMessage({
    required String senderName,
    required String message,
    required String senderId,
    String? chatId,
  }) {
    print('🔔 [NOTIFICATION SERVICE DEBUG] showInAppNotificationForMessage called');
    print('   👤 Sender: $senderName');
    print('   💬 Message: $message');
    print('   📱 App in foreground: $_isAppInForeground');
    print('   📡 Has stream listeners: ${_inAppNotificationController.hasListener}');
    
    if (_isAppInForeground) {
      print('🔔 [NOTIFICATION SERVICE DEBUG] Adding notification to stream');
      
      final notificationData = {
        'type': 'chat_message',
        'senderName': senderName,
        'message': message,
        'senderId': senderId,
        'chatId': chatId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('   📦 Notification data: $notificationData');
      
      _inAppNotificationController.add(notificationData);
      
      print('✅ [NOTIFICATION SERVICE DEBUG] Notification added to stream successfully');
    } else {
      print('⚠️ [NOTIFICATION SERVICE DEBUG] App not in foreground - would show push notification');
      // TODO: Show push notification when app is in background
    }
  }
  
  // Set app foreground state
  void setAppForegroundState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    print('🔔 [NOTIFICATION DEBUG] App foreground state: $_isAppInForeground');
  }
  
  // Get FCM token
  String? get fcmToken => _fcmToken;
  
  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await _localNotifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } else if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }
  
  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      // Android permissions are handled during initialization
      return await areNotificationsEnabled();
    }
    return false;
  }
  
  // Test method to manually trigger a notification
  void testNotification() {
    print('🔔 [NOTIFICATION SERVICE TEST] Triggering test notification');
    showInAppNotificationForMessage(
      senderName: 'Test Friend',
      message: 'This is a test notification!',
      senderId: 'test_id',
      chatId: 'test_chat',
    );
  }
  
  // Dispose
  void dispose() {
    _inAppNotificationController.close();
  }
}