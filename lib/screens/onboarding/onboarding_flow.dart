import 'package:flutter/material.dart';
import 'dart:io';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';
import 'onboarding_screen_4.dart';
import 'onboarding_screen_5.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

/// Main Onboarding Flow Controller
/// Manages the 5-screen onboarding process
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentScreen = 0;
  String? _selectedUserType;
  Map<String, dynamic>? _profileData;
  bool? _wantsVerification;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentScreen > 0) {
          setState(() {
            _currentScreen--;
          });
          return false;
        }
        return true;
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return OnboardingScreen1(
          onNext: () {
            setState(() {
              _currentScreen = 1;
            });
          },
        );
      case 1:
        return OnboardingScreen2(
          onUserTypeSelected: (userType) {
            setState(() {
              _selectedUserType = userType;
              _currentScreen = 2;
            });
          },
        );
      case 2:
        return OnboardingScreen3(
          userType: _selectedUserType!,
          onProfileComplete: (profileData) {
            setState(() {
              _profileData = profileData;
              _currentScreen = 3;
            });
          },
        );
      case 3:
        return OnboardingScreen4(
          userType: _selectedUserType!,
          profileData: _profileData!,
          onVerificationChoice: (wantsVerification) {
            setState(() {
              _wantsVerification = wantsVerification;
              _currentScreen = 4;
            });
          },
        );
      case 4:
        return OnboardingScreen5(
          onComplete: _completeOnboarding,
        );
      default:
        return OnboardingScreen1(
          onNext: () {
            setState(() {
              _currentScreen = 1;
            });
          },
        );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Prepare user data for backend
      final userData = {
        'userType': _selectedUserType,
        'displayName': _profileData!['displayName'],
        'age': _profileData!['age'],
        'gender': _profileData!['gender'],
        'bio': _profileData!['bio'],
        'wantsVerification': _wantsVerification,
      };

      // Upload profile image if provided
      if (_profileData!['profileImage'] != null) {
        try {
          final imageUrl = await _uploadProfileImage(_profileData!['profileImage']);
          userData['profileImage'] = imageUrl;
        } catch (e) {
          print('Failed to upload profile image: $e');
          // Continue without image
        }
      }

      // Update user profile in backend
      await _updateUserProfile(userData);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Complete onboarding
      widget.onComplete();

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadProfileImage(File imageFile) async {
    // This would integrate with your existing image upload service
    // For now, return a placeholder
    return 'https://example.com/profile-image.jpg';
  }

  Future<void> _updateUserProfile(Map<String, dynamic> userData) async {
    // This would integrate with your existing API service
    // For now, just simulate the API call
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real implementation, you would call:
    // await _apiService.updateUserProfile(userData);
    
    print('User profile updated: $userData');
  }
}

/// Onboarding Flow Manager
/// Handles onboarding state and navigation
class OnboardingFlowManager {
  static const String _onboardingKey = 'onboarding_completed';
  
  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    // This would check with your storage service
    // For now, return false to always show onboarding
    return false;
  }
  
  /// Mark onboarding as completed
  static Future<void> markOnboardingCompleted() async {
    // This would save to your storage service
    // For now, just simulate
    print('Onboarding marked as completed');
  }
  
  /// Reset onboarding (for testing)
  static Future<void> resetOnboarding() async {
    // This would clear from your storage service
    print('Onboarding reset');
  }
}
