import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/config.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_service.dart';

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
      backgroundColor: const Color(0xFF2D1B69), // Dark purple background
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Upper section with Welcome and Logo
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 80,
                        height: 80,
                        child: Image.asset(
                          'assets/images/purplt-chatify-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lower section with action buttons
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Connect with people around the world',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Google logo colors
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF4285F4), // Blue
                                              Color(0xFF34A853), // Green
                                              Color(0xFFFBBC05), // Yellow
                                              Color(0xFFEA4335), // Red
                                            ],
                                            stops: [0.0, 0.25, 0.5, 0.75],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'G',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                            label: Text(
                              _isLoading ? 'Connecting...' : 'Connect with Google',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Or divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Guest Button
                        SizedBox(
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
                                : Icon(
                                    Icons.person_outline,
                                    color: Colors.grey[600],
                                  ),
                            label: Text(
                              _isLoading ? 'Connecting...' : 'Continue as Guest',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Terms and privacy
                        Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // Sign in as Guest
  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInAsGuest();
      if (result['success'] == true) {
        // Show profile creation popup for guest users
        await _showGuestProfilePopup();
      } else {
        _showError(result['message'] ?? 'Guest sign-in failed');
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
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/profile-management',
                    arguments: {'isGuestUser': true});
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
      final isNewUser = result['isNewUser'] ?? false;

      // Navigate based on user status
      if (isNewUser) {
        // New user - go to profile creation or onboarding
        Navigator.pushReplacementNamed(context, '/profile-management');
      } else {
        // Existing user - go to main app
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      _showError(result['message'] ?? 'Authentication failed');
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
    final authService = AuthService();

    // Test basic connectivity
    final canConnect = await authService.testBackendConnection();

    if (canConnect) {
      // Test POST requests
      final canPost = await authService.testPostRequest();

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
    showDialog(
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
                config['apiUrl'],
                style: TextStyle(fontFamily: 'monospace', color: Colors.blue),
              ),
              SizedBox(height: 12),
              Text('Troubleshooting:'),
              SizedBox(height: 4),
              Text('• Make sure backend is running on port 3000'),
              Text('• For physical device, use your computer\'s IP'),
              Text('• For emulator, 10.0.2.2 should work'),
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
              Clipboard.setData(ClipboardData(text: config['apiUrl']));
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
}
