import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:screen_protector/screen_protector.dart';
import 'app.dart';
import 'services/background_image_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [BACKGROUND NOTIFICATION] Handling background message: ${message.messageId}');
  print('   📦 Title: ${message.notification?.title}');
  print('   📦 Body: ${message.notification?.body}');
  print('   📦 Data: ${message.data}');
  
  try {
    // Handle image messages for auto-save even when app is closed
    final backgroundImageService = BackgroundImageService();
    await backgroundImageService.handleImageFromPushNotification(message.data);
    print('✅ [BACKGROUND NOTIFICATION] Image processing completed');
  } catch (e) {
    print('❌ [BACKGROUND NOTIFICATION] Error processing image: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize security features - prevent screenshots and screen recording
  await _initializeSecurity();
  
  // Try to initialize Firebase, but don't crash if it fails
  try {
    await Firebase.initializeApp();
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    print('✅ Firebase initialized successfully with notifications');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('Running without Firebase - some features may not work');
  }
  
  runApp(const ChatApp());
}

Future<void> _initializeSecurity() async {
  try {
    // Enable security features - prevent screenshots and screen recording
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
    
    print('🔒 Security features initialized - Screenshots and screen recording blocked');
  } catch (e) {
    print('⚠️ Failed to initialize security features: $e');
  }
}
