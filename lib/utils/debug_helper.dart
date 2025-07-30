import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DebugHelper {
  static Future<void> verifyGoogleSignInConfig() async {
    // print('🔍 Verifying Google Sign-In Configuration...');

    try {
      // Check if Google Play Services is available
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Test if we can access Google Sign-In
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();

      if (account != null) {
        // print('✅ Google Sign-In is properly configured');
        // print('📧 Current account: ${account.email}');
      } else {
        // print('ℹ️ No existing Google account found (this is normal)');
      }

      // Test the sign-in flow (without actually signing in)
      try {
        await googleSignIn.signIn();
        // print('✅ Google Sign-In flow is working');
      } catch (e) {
        // print('❌ Google Sign-In error: $e');
        // print('💡 This might be due to SHA-1 fingerprint mismatch');
      }
    } catch (e) {
      // print('❌ Google Sign-In configuration error: $e');
    }
  }

  static Future<void> checkFirebaseConfig() async {
    // print('🔍 Checking Firebase Configuration...');

    try {
      // Check if google-services.json exists
      final file = File('android/app/google-services.json');
      if (await file.exists()) {
        // print('✅ google-services.json found');

        // Read and parse the file
        final content = await file.readAsString();
        final data = Map<String, dynamic>.from(
            // Simple JSON parsing for debugging
            content.contains('"certificate_hash"')
                ? {'has_certificate_hash': true}
                : {'has_certificate_hash': false});

        if (data['has_certificate_hash'] == true) {
          // print('✅ Certificate hash found in google-services.json');
        } else {
          // print('❌ Certificate hash not found in google-services.json');
        }
      } else {
        // print('❌ google-services.json not found');
      }
    } catch (e) {
      // print('❌ Error checking Firebase config: $e');
    }
  }

  static void printCurrentSHA1() {
    // print('🔍 Current SHA-1 Fingerprint:');
    // print('SHA1: C5:8C:49:8B:5B:35:6A:93:D0:18:1B:37:AD:E7:73:78:39:42:ED:EF');
    // print('Formatted: c58c498b5b356a93d0181b37ade773783942edef');
    // print('💡 Make sure this matches your Firebase console configuration');
  }
}
