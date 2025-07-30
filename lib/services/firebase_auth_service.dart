import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/config.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Backend URL from config
  String get _backendUrl => '${AppConfig.apiUrl}/auth/login';

  // Test backend connectivity
  Future<Map<String, dynamic>> testBackendConnection() async {
    // print('🔍 DEBUG: Testing backend connection...');
    // print('🔍 DEBUG: Backend URL: ${AppConfig.apiUrl}');

    try {
      final testUrl = '${AppConfig.apiUrl}/auth/test-connection';
      // print('🔍 DEBUG: Test URL: $testUrl');

      final response = await http.get(
        Uri.parse(testUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      // print('🔍 DEBUG: Test response status: ${response.statusCode}');
      // print('🔍 DEBUG: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Backend connection successful',
          'data': data,
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // print('🔍 DEBUG: Backend connection test failed: $e');
      throw Exception('Backend connection failed: $e');
    }
  }

  // Test POST request
  Future<Map<String, dynamic>> testPostRequest() async {
    // print('🔍 DEBUG: Testing POST request...');

    try {
      final testUrl = '${AppConfig.apiUrl}/auth/test-post';
      // print('🔍 DEBUG: POST Test URL: $testUrl');

      final response = await http
          .post(
            Uri.parse(testUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'test': 'data',
              'from': 'flutter',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Duration(seconds: 10));

      // print('🔍 DEBUG: POST response status: ${response.statusCode}');
      // print('🔍 DEBUG: POST response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'POST request successful',
          'data': data,
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // print('🔍 DEBUG: POST request test failed: $e');
      throw Exception('POST request failed: $e');
    }
  }

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
      throw Exception(
          'Firebase is not configured. Please add Firebase configuration files:\n\n'
          '1. Add google-services.json to android/app/\n'
          '2. Add GoogleService-Info.plist to ios/Runner/\n'
          '3. Restart the app\n\n'
          'For now, you can use "Continue as Guest" to test the app.');
    }

    // print('🚀 Starting Google Sign-In...');

    try {
      // Trigger the authentication flow
      // print('📱 Opening Google Sign-In popup...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // print('❌ Google sign-in cancelled by user');
        throw Exception('Google sign-in cancelled');
      }

      // print('✅ Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      // print('🔑 Getting Google authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // print('🎫 Creating Firebase credential...');
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // print('🔥 Signing in to Firebase...');
      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth!.signInWithCredential(credential);

      // print('✅ Firebase sign-in successful: ${userCredential.user?.email}');

      // Get the Firebase ID token
      // print('🎟️ Getting Firebase ID token...');
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        // print('❌ Failed to get Firebase ID token');
        throw Exception('Failed to get Firebase ID token');
      }

      // print('✅ Firebase ID token obtained');

      // Send token to your backend with user data
      return await _sendTokenToBackend(idToken, 'google', {
        'displayName': userCredential.user?.displayName,
        'photoURL': userCredential.user?.photoURL,
        'email': userCredential.user?.email,
      });
    } catch (e) {
      // print('🚨 Google sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign in with Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    if (!isFirebaseAvailable) {
      throw Exception(
          'Firebase is not configured. Please add Firebase configuration files:\n\n'
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
      final UserCredential userCredential =
          await _auth!.signInWithCredential(oauthCredential);

      // Get the Firebase ID token
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Send token to your backend with user data
      return await _sendTokenToBackend(idToken, 'apple', {
        'displayName': userCredential.user?.displayName,
        'photoURL': userCredential.user?.photoURL,
        'email': userCredential.user?.email,
      });
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

      // Send token to your backend with device ID
      return await _sendTokenToBackend(idToken, 'anonymous', {
        'deviceId': 'flutter-device-${DateTime.now().millisecondsSinceEpoch}',
      });
    } catch (e) {
      throw Exception('Guest sign-in failed: $e');
    }
  }

  // Send Firebase ID token to your backend
  Future<Map<String, dynamic>> _sendTokenToBackend(
      String idToken, String provider, Map<String, dynamic> userData) async {
    // print('🔐 Sending token to backend...');
    // print('📍 URL: $_backendUrl');
    // print('🔑 Provider: $provider');
    // print('📱 Token length: ${idToken.length}');

    try {
      // Build request body based on provider
      final Map<String, dynamic> requestBody = {
        'signInProvider': provider,
      };

      // Add displayName if available
      if (userData['displayName'] != null) {
        requestBody['displayName'] = userData['displayName'];
      }

      // Add photoURL if available
      if (userData['photoURL'] != null) {
        requestBody['photoURL'] = userData['photoURL'];
      }

      // Only add deviceId for anonymous users
      if (provider == 'anonymous' && userData['deviceId'] != null) {
        requestBody['deviceId'] = userData['deviceId'];
      }

      // print('🔍 DEBUG: Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(AppConfig.apiTimeout);

      // print('📡 Response status: ${response.statusCode}');
      // print('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // print('✅ Backend response successful');
        // print('🔍 DEBUG: Parsed response data: $data');

        // Extract user data from the correct location
        final userData = data['data']['user'];
        // print('🔍 DEBUG: User data: $userData');

        return {
          'success': true,
          'user': userData,
          'isNewUser': userData['isNewUser'] ?? false,
          'message': data['message'],
        };
      } else if (response.statusCode == 429) {
        // Handle rate limiting specifically
        // print('⚠️ Rate limit exceeded');
        final data = jsonDecode(response.body);
        final retryAfter = data['retryAfter'] ?? 900; // Default to 15 minutes
        final retryMinutes = (retryAfter / 60).ceil();

        throw Exception(
            'Rate limit exceeded. Please try again in $retryMinutes minutes.\n\nTip: If you\'re testing frequently, restart the backend server to reset the rate limits.');
      } else {
        // print('❌ Backend error: ${response.statusCode} - ${response.body}');
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Backend authentication failed';
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      // print('🚨 Backend request failed: $e');
      throw Exception('Failed to authenticate with backend: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      await _auth?.signOut();
    }
    await _googleSignIn.signOut();
  }

  // Get current Firebase ID token
  Future<String?> getIdToken() async {
    if (!isFirebaseAvailable || currentUser == null) {
      return null;
    }
    return await currentUser!.getIdToken();
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }
}
