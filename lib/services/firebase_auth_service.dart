import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
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
      final apps = Firebase.apps;
      print('🔍 DEBUG: Firebase apps count: ${apps.length}');

      if (apps.isEmpty) {
        print('❌ DEBUG: No Firebase apps found');
        return false;
      }

      _auth ??= FirebaseAuth.instance;
      print('✅ DEBUG: Firebase is available');
      return true;
    } catch (e) {
      print('❌ DEBUG: Firebase availability check failed: $e');
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

    // Retry logic for Render free tier wake-up
    const maxRetries = 5; // Increased for Render wake-up
    const retryDelay = Duration(seconds: 3); // Increased delay
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
        // print('🔄 Attempt $attempt of $maxRetries');

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
        } else if (response.statusCode == 503) {
          // Backend is sleeping (Render free tier)
          if (attempt < maxRetries) {
            // print('⏳ Backend sleeping, waiting ${retryDelay.inSeconds}s before retry...');
            await Future.delayed(retryDelay);
            continue; // Retry
          } else {
            // Final attempt failed
            throw Exception('Backend service is temporarily unavailable. The server may be waking up. Please try again in a moment.');
          }
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
          String errorMessage = 'Backend authentication failed';
          
          // Check if response is HTML (e.g., Render sleep page or error page)
          if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
            if (response.statusCode == 503) {
              errorMessage = 'Backend service is temporarily unavailable. Please try again in a moment.';
            } else {
              errorMessage = 'Backend returned invalid response. Please check if the backend is running.';
            }
          } else {
            try {
              final data = jsonDecode(response.body);
              errorMessage = data['message'] ?? 'Backend authentication failed';
            } catch (_) {
              // If parsing fails, use the raw response
              errorMessage = 'Backend error: ${response.statusCode}';
            }
          }
          
          throw Exception('$errorMessage (Status: ${response.statusCode})');
        }
      } catch (e) {
        final errorMsg = e.toString();
        
        // Handle timeout or connection errors
        if (errorMsg.contains('TimeoutException') || errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
          if (attempt < maxRetries) {
            // print('⏳ Connection failed, retrying in ${retryDelay.inSeconds}s...');
            await Future.delayed(retryDelay);
            continue; // Retry
          }
        }
        
        // Handle FormatException (HTML response)
        if (errorMsg.contains('FormatException') || errorMsg.contains('Unexpected character')) {
          if (attempt < maxRetries) {
            // print('⏳ Backend returned HTML (sleeping), retrying in ${retryDelay.inSeconds}s...');
            await Future.delayed(retryDelay);
            continue; // Retry
          }
          throw Exception('Backend returned invalid response (HTML instead of JSON). The backend may be sleeping or unavailable. Please try again in a moment.');
        }
        
        // If this is the last attempt or error is not retryable, throw
        if (attempt == maxRetries) {
          throw Exception('Failed to authenticate with backend: $e');
        }
        
        // Otherwise, retry
        await Future.delayed(retryDelay);
      }
    }
    
    // Should never reach here, but just in case
    throw Exception('Failed to authenticate with backend after $maxRetries attempts');
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
    try {
      print('🔍 DEBUG: Getting Firebase ID token...');

      if (!isFirebaseAvailable) {
        print('❌ DEBUG: Firebase is not available');
        return null;
      }

      if (currentUser == null) {
        print('❌ DEBUG: No current user found');
        return null;
      }

      print('🔍 DEBUG: Current user: ${currentUser!.uid}');
      print('🔍 DEBUG: User email: ${currentUser!.email}');
      print('🔍 DEBUG: User is anonymous: ${currentUser!.isAnonymous}');

      final token = await currentUser!.getIdToken();

      if (token != null) {
        print(
            '✅ DEBUG: Firebase token retrieved successfully (length: ${token.length})');
        print('🔍 DEBUG: Token starts with: ${token.substring(0, 20)}...');
      } else {
        print('❌ DEBUG: Firebase token is null');
      }

      return token;
    } catch (e) {
      print('🚨 DEBUG: Error getting Firebase token: $e');
      print('🚨 DEBUG: Error type: ${e.runtimeType}');

      // Check if it's a PlatformException
      if (e.toString().contains('PlatformException')) {
        print(
            '🚨 DEBUG: This is a PlatformException - likely Firebase configuration issue');
      }

      return null;
    }
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }
}
