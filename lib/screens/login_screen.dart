import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/app_logo.dart';
import '../app.dart' show navigatorKey;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Upper section with logo and welcome text
            Expanded(
              flex: 1,
              child: _buildUpperSection(),
            ),

            // Lower section with login panel
            _buildLoginPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Purple Chatify logo
          AppLogo(
            size: 120,
          ),
          const SizedBox(height: 24),

          // Welcome text
          Text(
            'Welcome',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPanel() {
    return GlassCard(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtitle
          Text(
            'Connect with people around the world',
            style: TextStyle(
              fontSize: 18, // Increased for better readability
              color: Colors.white,
              fontWeight:
                  FontWeight.w600, // Increased weight for better readability
              height: 1.4, // Added line height for better text flow
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Google Sign In Button
          _buildGoogleButton(),
          const SizedBox(height: 16),

          // Apple Sign In Button (only show on iOS)
          if (Platform.isIOS) ...[
            _buildAppleButton(),
            const SizedBox(height: 16),
          ],

          // Or divider
          _buildDivider(),
          const SizedBox(height: 16),

          // Guest button
          _buildGuestButton(),
          const SizedBox(height: 24),

          // Terms and privacy
          _buildTermsText(),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    final isFirebaseAvailable = _authService.isFirebaseAvailable;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            isFirebaseAvailable && !_isLoading ? _signInWithGoogle : null,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: Colors.black87,
              ),
        label: Text(
          isFirebaseAvailable
              ? 'Connect with Google'
              : 'Google (Requires Firebase)',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 17, // Increased for better readability
            fontWeight:
                FontWeight.w600, // Increased weight for better readability
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    final isFirebaseAvailable = _authService.isFirebaseAvailable;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isFirebaseAvailable && !_isLoading ? _signInWithApple : null,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.apple,
                size: 24,
                color: Colors.white,
              ),
        label: Text(
          isFirebaseAvailable
              ? 'Connect with Apple'
              : 'Apple (Requires Firebase)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17, // Increased for better readability
            fontWeight:
                FontWeight.w600, // Increased weight for better readability
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInAsGuest,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
        label: const Text(
          'Continue as Guest',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17, // Increased for better readability
            fontWeight:
                FontWeight.w600, // Increased weight for better readability
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF6B46C1).withOpacity(0.9), // Purple color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: TextStyle(
        fontSize: 14, // Increased from 12 for much better readability
        color: Colors.white
            .withOpacity(0.8), // Increased opacity for better contrast
        fontWeight: FontWeight.w500, // Added weight for better readability
        height: 1.5, // Increased line height for better text flow
      ),
      textAlign: TextAlign.center,
    );
  }

  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();
      await _handleAuthResult(result);
    } catch (e) {
      _showError('Google sign-in failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sign in with Apple
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithApple();
      await _handleAuthResult(result);
    } catch (e) {
      _showError('Apple sign-in failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sign in as Guest
  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInAsGuest();
      if (result['success'] == true) {
        // Show profile creation popup for guest users
        await _showGuestProfilePopup();
      } else {
        _showError((result['message'] as String?) ?? 'Guest sign-in failed');
      }
    } catch (e) {
      _showError('Guest sign-in failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show popup for guest users to create profile
  Future<void> _showGuestProfilePopup() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.orange),
              SizedBox(width: 8),
              Text('Create Profile'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the app!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Creating a profile is IMPORTANT for the best experience:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('• Connect with other users'),
              Text('• Personalize your chat experience'),
              Text('• Access all app features'),
              SizedBox(height: 12),
              Text(
                'We\'ll help you get started with some basic information.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Use global navigator key to ensure proper routing context
                navigatorKey.currentState?.pushReplacementNamed('/home');
              },
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Use global navigator key to ensure proper routing context
                navigatorKey.currentState?.pushReplacementNamed('/onboarding');
              },
              child: const Text('Create Profile'),
            ),
          ],
        );
      },
    );
  }

  // Handle authentication result from backend
  Future<void> _handleAuthResult(Map<String, dynamic> result) async {
    if (result['success'] == true) {
      final user = result['user'];
      final isNewUser = (result['isNewUser'] as bool?) ?? false;

      // Navigate based on user status
      if (isNewUser == true) {
        // New user - go to onboarding
        navigatorKey.currentState?.pushReplacementNamed('/onboarding');
      } else {
        // Existing user - go to main app
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } else {
      _showError((result['message'] as String?) ?? 'Authentication failed');
    }
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _testConnection() async {
    // print('🔍 DEBUG: Starting connection test...');
    // print('🔍 DEBUG: Platform config: ${AppConfig.debugInfo}');

    final authService = AuthService();

    // Test basic connectivity
    final canConnect = await authService.testBackendConnection();
    // print('🔍 DEBUG: Can connect to backend: $canConnect');

    if (canConnect) {
      // Test POST requests
      final canPost = await authService.testPostRequest();
      // print('🔍 DEBUG: Can make POST requests: $canPost');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Backend connection successful!\nUsing: ${AppConfig.apiUrl}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      // Show error message with suggestions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❌ Cannot connect to backend\nTrying: ${AppConfig.apiUrl}\nTap "Show Debug Info" for help'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  void _showDebugInfo() {
    final config = AppConfig.debugInfo;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔍 Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Platform: ${config['platform']}'),
              SizedBox(height: 8),
              Text('Current API URL:'),
              SelectableText(
                config['apiUrl'] as String? ?? 'N/A',
                style: TextStyle(fontFamily: 'monospace', color: Colors.blue),
              ),
              SizedBox(height: 12),
              Text('Troubleshooting:'),
              SizedBox(height: 4),
              Text('• Make sure backend is running on port 3000'),
              Text('• For physical device, use your computer\'s IP'),
              Text('• For emulator, 10.0.2.2 should work'),
              SizedBox(height: 8),
              // Text('Alternative URL for physical device:'),
              // SelectableText(
              //   config['physicalDeviceApiUrl'],
              //   style: TextStyle(fontFamily: 'monospace', color: Colors.orange),
              // ),
              SizedBox(height: 8),
              Text('To find your IP:'),
              Text('Windows: ipconfig'),
              Text('Mac/Linux: ifconfig'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: config['apiUrl'] as String? ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('API URL copied to clipboard')),
              );
            },
            child: Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // void _testPhysicalDeviceConnection() async {
  //   // print('🔍 DEBUG: Testing with physical device IP...');
  //
  //   // Temporarily override the API URL for testing
  //   final testUrl = AppConfig.physicalDeviceApiUrl;
  //   // print('🔍 DEBUG: Testing URL: $testUrl');
  //
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$testUrl/api/auth/test-connection'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //       },
  //     ).timeout(Duration(seconds: 10));
  //
  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //               '✅ Physical device IP works!\nUpdate your config with this IP'),
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 4),
  //         ),
  //       );
  //     } else {
  //       throw Exception('HTTP ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('❌ Physical device IP failed: $e'),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 4),
  //       ),
  //     );
  //   }
  // }
}
