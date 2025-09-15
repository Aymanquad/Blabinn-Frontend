import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'services/background_image_service.dart';
import 'services/ad_service.dart';
import 'utils/logger.dart';
import 'utils/global_error_handler.dart';
import 'utils/ad_debug_helper.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.notification('Handling background message: ${message.messageId}');
  Logger.debug('Title: ${message.notification?.title}');
  Logger.debug('Body: ${message.notification?.body}');
  Logger.debug('Data: ${message.data}');

  try {
    // Handle image messages for auto-save even when app is closed
    final backgroundImageService = BackgroundImageService();
    await backgroundImageService.handleImageFromPushNotification(message.data);
    Logger.notification('Image processing completed');
  } catch (e) {
    Logger.error('Error processing image', error: e);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handler first
  GlobalErrorHandler.initialize();

  // Initialize security features - allow screenshots by default
  await _initializeSecurity();

  // Try to initialize Firebase, but don't crash if it fails
  try {
    Logger.info('Initializing Firebase...');
    await Firebase.initializeApp();
    Logger.info('Firebase initialized successfully');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    Logger.info('Firebase messaging background handler set up');
  } catch (e) {
    Logger.error('Firebase initialization failed', error: e);
    Logger.warning('Running without Firebase - some features may not work');
  }

  // Initialize AdMob
  try {
    Logger.ads('Initializing AdMob...');

    // Print debug information
    AdDebugHelper.printAdConfig();
    AdDebugHelper.validateAdConfig();

    await MobileAds.instance.initialize();
    Logger.ads('AdMob initialized successfully');
  } catch (e) {
    Logger.error('AdMob initialization failed', error: e);
    Logger.warning('Running without AdMob - ads will not be displayed');
    Logger.info('Make sure you have internet connection and valid AdMob IDs');
  }

  // Initialize Billing Service
  try {
    Logger.billing('Initializing Billing Service...');
    // Billing service is now initialized per screen, not globally
    Logger.billing('Billing Service will be initialized when needed');
  } catch (e) {
    Logger.error('Billing Service initialization failed', error: e);
    Logger.warning('Running without billing - purchases will not work');
  }

  runApp(const ChatApp());
}

Future<void> _initializeSecurity() async {
  try {
    // Allow screenshots by default; selective screens will enable protection
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    Logger.info('Screenshots enabled globally; protected per-screen where needed');
  } catch (e) {
    Logger.warning('Failed to initialize security features', error: e);
  }
}
