import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Simple fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startSplashSequence() async {
    // Start fade animation
    await _fadeController.forward();

    // Initialize UserProvider
    bool isAuthenticated = false;
    bool hasCompletedProfile = false;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initialize();
      isAuthenticated = userProvider.currentUser != null;
      if (isAuthenticated) {
        hasCompletedProfile = userProvider.currentUser!.hasCompletedProfile;
      }
    } catch (e) {
      //print('UserProvider initialization failed: $e');
    }

    // Wait for total splash duration, then navigate
    await Future.delayed(const Duration(milliseconds: 1000));
    if (isAuthenticated) {
      if (hasCompletedProfile) {
        _navigateToHome();
      } else {
        _navigateToProfileCompletion();
      }
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _navigateToProfileCompletion() {
    Navigator.of(context).pushReplacementNamed('/profile-management');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/violettoblack_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Purple Chatify logo
                Container(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/images/chatify_purple_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Chatify text
                Text(
                  'Chatify',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
