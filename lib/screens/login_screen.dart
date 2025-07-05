import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../core/constants.dart';
import '../services/firebase_auth_service.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and title
              _buildHeader(),
              const SizedBox(height: 48),
              
              // Firebase status indicator
              _buildFirebaseStatus(),
              const SizedBox(height: 24),
              
              // Sign in buttons
              _buildSignInButtons(),
              const SizedBox(height: 24),
              
              // Or divider
              _buildDivider(),
              const SizedBox(height: 24),
              
              // Guest button
              _buildGuestButton(),
              const SizedBox(height: 32),
              
              // Terms and privacy
              _buildTermsText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 50,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to ${AppConstants.appName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with people around the world',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFirebaseStatus() {
    final isFirebaseAvailable = _authService.isFirebaseAvailable;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirebaseAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFirebaseAvailable ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFirebaseAvailable ? Icons.check_circle : Icons.warning,
            color: isFirebaseAvailable ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFirebaseAvailable 
                  ? 'Firebase configured - All features available'
                  : 'Firebase not configured - Limited features available',
              style: TextStyle(
                fontSize: 12,
                color: isFirebaseAvailable ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButtons() {
    final isFirebaseAvailable = _authService.isFirebaseAvailable;
    
    return Column(
      children: [
        // Google Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: isFirebaseAvailable && !_isLoading ? _signInWithGoogle : null,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.asset(
                    'assets/images/google_logo.png', // You'll need to add this
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata),
                  ),
            label: Text(isFirebaseAvailable ? 'Continue with Google' : 'Google (Requires Firebase)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFirebaseAvailable ? Colors.white : Colors.grey[200],
              foregroundColor: isFirebaseAvailable ? Colors.black87 : Colors.grey[600],
              side: BorderSide(color: isFirebaseAvailable ? Colors.grey : Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Apple Sign In Button (only show on iOS)
        if (Platform.isIOS) ...[
          SizedBox(
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
                  : const Icon(Icons.apple, size: 24),
              label: Text(isFirebaseAvailable ? 'Continue with Apple' : 'Apple (Requires Firebase)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFirebaseAvailable ? Colors.black : Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInAsGuest,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_outline),
        label: const Text('Continue as Guest'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
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
      await _handleAuthResult(result);
    } catch (e) {
      _showError('Guest sign-in failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle authentication result from backend
  Future<void> _handleAuthResult(Map<String, dynamic> result) async {
    if (result['success'] == true) {
      final user = result['user'];
      final isNewUser = result['isNewUser'] ?? false;
      
      // Navigate based on user status
      if (isNewUser) {
        // New user - go to profile creation or onboarding
        Navigator.pushReplacementNamed(context, '/profile-setup');
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
} 