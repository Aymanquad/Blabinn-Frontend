import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:screen_protector/screen_protector.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize security features - prevent screenshots and screen recording
  await _initializeSecurity();
  
  // Try to initialize Firebase, but don't crash if it fails
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
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
