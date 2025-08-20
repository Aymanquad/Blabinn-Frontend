import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'services/background_image_service.dart';
import 'services/ad_service.dart';
import 'services/billing_service.dart';
import 'utils/ad_debug_helper.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // print('🔔 [BACKGROUND NOTIFICATION] Handling background message: ${message.messageId}');
  // print('   📦 Title: ${message.notification?.title}');
  // print('   📦 Body: ${message.notification?.body}');
  // print('   📦 Data: ${message.data}');

  try {
    // Handle image messages for auto-save even when app is closed
    final backgroundImageService = BackgroundImageService();
    await backgroundImageService.handleImageFromPushNotification(message.data);
    // print('✅ [BACKGROUND NOTIFICATION] Image processing completed');
  } catch (e) {
    // print('❌ [BACKGROUND NOTIFICATION] Error processing image: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize security features - prevent screenshots and screen recording
  await _initializeSecurity();

  // Try to initialize Firebase, but don't crash if it fails
  try {
    // print('🔍 DEBUG: Initializing Firebase...');
    await Firebase.initializeApp();
    // print('✅ DEBUG: Firebase initialized successfully');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // print('✅ DEBUG: Firebase messaging background handler set up');
  } catch (e) {
    // print('❌ DEBUG: Firebase initialization failed: $e');
    // print('❌ DEBUG: Error type: ${e.runtimeType}');
    // print('⚠️ DEBUG: Running without Firebase - some features may not work');
  }

  // Initialize AdMob
  try {
    // print('🔍 DEBUG: Initializing AdMob...');

    // Print debug information
    AdDebugHelper.printAdConfig();
    AdDebugHelper.validateAdConfig();

    await MobileAds.instance.initialize();
    // print('✅ DEBUG: AdMob initialized successfully');
  } catch (e) {
    // print('❌ DEBUG: AdMob initialization failed: $e');
    // print('⚠️ DEBUG: Running without AdMob - ads will not be displayed');
    // print('💡 DEBUG: Make sure you have internet connection and valid AdMob IDs');
  }

  // Initialize Billing Service
  try {
    // print('🔍 DEBUG: Initializing Billing Service...');
    await billingService.initialize();
    // print('✅ DEBUG: Billing Service initialized successfully');
  } catch (e) {
    // print('❌ DEBUG: Billing Service initialization failed: $e');
    // print('⚠️ DEBUG: Running without billing - purchases will not work');
  }

  runApp(const ChatApp());
}

Future<void> _initializeSecurity() async {
  try {
    // Enable security features - prevent screenshots and screen recording
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();

    // print('🔒 Security features initialized - Screenshots and screen recording blocked');
  } catch (e) {
    // print('⚠️ Failed to initialize security features: $e');
  }
}
