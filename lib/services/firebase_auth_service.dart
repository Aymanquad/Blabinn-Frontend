import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Your backend URL
  final String _backendUrl = 'http://localhost:3000/api/auth/login';

  // Check if Firebase is available
  bool get isFirebaseAvailable {
    try {
      Firebase.apps.isNotEmpty;
      _auth ??= FirebaseAuth.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  User? get currentUser => isFirebaseAvailable ? _auth?.currentUser : null;

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (!isFirebaseAvailable) {
      throw Exception('Firebase is not configured. Please add Firebase configuration files:\n\n'
          '1. Add google-services.json to android/app/\n'
          '2. Add GoogleService-Info.plist to ios/Runner/\n'
          '3. Restart the app\n\n'
          'For now, you can use "Continue as Guest" to test the app.');
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      
      // Get the Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send token to your backend
      return await _sendTokenToBackend(idToken, 'google');
      
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign in with Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    if (!isFirebaseAvailable) {
      throw Exception('Firebase is not configured. Please add Firebase configuration files:\n\n'
          '1. Add google-services.json to android/app/\n'
          '2. Add GoogleService-Info.plist to ios/Runner/\n'
          '3. Restart the app\n\n'
          'For now, you can use "Continue as Guest" to test the app.');
    }

    try {
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth!.signInWithCredential(oauthCredential);
      
      // Get the Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send token to your backend
      return await _sendTokenToBackend(idToken, 'apple');
      
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  // Sign in as Guest (anonymous) - works without Firebase for testing
  Future<Map<String, dynamic>> signInAsGuest() async {
    if (!isFirebaseAvailable) {
      // Return a mock result for testing when Firebase is not available
      return {
        'success': true,
        'user': {
          'uid': 'guest-user-123',
          'email': 'guest@example.com',
          'displayName': 'Guest User',
          'photoURL': null,
        },
        'isNewUser': false,
        'message': 'Signed in as guest (Firebase not configured)',
      };
    }

    try {
      // Sign in anonymously
      final UserCredential userCredential = await _auth!.signInAnonymously();
      
      // Get the Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send token to your backend
      return await _sendTokenToBackend(idToken, 'guest');
      
    } catch (e) {
      throw Exception('Guest sign-in failed: $e');
    }
  }

  // Send Firebase ID token to your backend
  Future<Map<String, dynamic>> _sendTokenToBackend(String idToken, String provider) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'idToken': idToken,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Backend responded with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to authenticate with backend: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!isFirebaseAvailable) {
      return; // Nothing to sign out from
    }

    try {
      await _auth!.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => isFirebaseAvailable ? (_auth?.currentUser != null) : false;

  // Get user display name
  String? get userDisplayName => isFirebaseAvailable ? _auth?.currentUser?.displayName : null;

  // Get user email
  String? get userEmail => isFirebaseAvailable ? _auth?.currentUser?.email : null;

  // Get user photo URL
  String? get userPhotoURL => isFirebaseAvailable ? _auth?.currentUser?.photoURL : null;
} 