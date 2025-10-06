import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme_extensions.dart';
import '../chat/random_chat_screen.dart';
import '../connect/connect_state_manager.dart';
import '../connect/connect_ui_components.dart';
import '../connect/connect_dialog_components.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late ConnectStateManager _stateManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStateManager();
    _setupStateManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  void _initializeStateManager() {
    _stateManager = ConnectStateManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      onNavigateToChat: _navigateToRandomChat,
      onShowTimeoutDialog: () {
        if (mounted) {
          ConnectDialogComponents.showTimeoutDialog(context, _stateManager);
        }
      },
      onShowWarningSnackBar: (message, color) {
        if (mounted) {
          ConnectDialogComponents.showWarningSnackBar(context, message, color);
        }
      },
      onShowClearSessionDialog: () {
        if (mounted) {
          ConnectDialogComponents.showClearSessionDialog(
              context, _stateManager);
        }
      },
    );
  }

  void _setupStateManager() {
    _stateManager.initializeServices();
    _stateManager.initializeAnimations(this);
    _stateManager.initializeFilters();
    _stateManager.setupSocketListeners();
    _stateManager.loadUserInterests();
  }

  Future<void> _loadContent() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  void _navigateToRandomChat(
    String sessionId,
    String chatRoomId, {
    bool isAiChat = false,
    Map<String, dynamic>? aiUser,
  }) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => RandomChatScreen(
            sessionId: sessionId,
            chatRoomId: chatRoomId,
            isAiChat: isAiChat,
            aiUser: aiUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(context, tokens)
            : _buildMainContent(context, tokens),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppThemeTokens? tokens) {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AppThemeTokens? tokens) {
    if (_stateManager.isMatching) {
      return ConnectUIComponents.buildMatchingScreen(context, _stateManager);
    }

    return _buildHeroSection(context);
  }

  Widget _buildHeroSection(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              100, // Account for bottom navigation
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero Image Section
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background image container
                    Center(
                      child: Container(
                        width: 250,
                        height: 300,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/images/Girl.png'),
                            fit: BoxFit.contain,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/Girl.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Image Error: $error');
                            return Image.asset(
                              'assets/images/girl_new_use_nobg.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Fallback Image Error: $error');
                                return Image.asset(
                                  'assets/images/girl_new-removebg-preview.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        'Second Fallback Image Error: $error');
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Color(0x80FFFFFF),
                                        size: 64,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Text overlay positioned above the waist area
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Ready to meet new people?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // Connect Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D8B5CF6),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      if (mounted) {
                        _stateManager.startMatching();
                      }
                    },
                    child: Center(
                      child: Text(
                        'Connect Now',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Test AI Button (for debugging)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D10B981),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (mounted) {
                        _testAiChat();
                      }
                    },
                    child: Center(
                      child: Text(
                        'Test AI Chat (Debug)',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Descriptive text
              Text(
                'Find and chat with people around the world',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),

              // Bottom spacing for navigation bar
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _testAiChat() {
    print('[DEBUG] Test AI Chat button pressed');

    // Create a fake AI session
    final aiSessionId =
        'test_ai_session_${DateTime.now().millisecondsSinceEpoch}';

    // Create fake AI user profile
    final aiUser = {
      'id': 'test_ai_user_${DateTime.now().millisecondsSinceEpoch}',
      'username': 'AI Test Partner',
      'bio': 'This is a test AI partner for debugging!',
      'profileImage': null,
      'interests': ['testing', 'debugging', 'chatting'],
      'language': 'en',
      'isOnline': true,
      'lastSeen': DateTime.now().toIso8601String(),
      'isPremium': false,
      'age': 25,
      'gender': 'Other',
      'userType': 'ai_chatbot',
      'isVerified': false,
    };

    print('[DEBUG] Navigating to test AI chat with session: $aiSessionId');

    _navigateToRandomChat(
      aiSessionId,
      aiSessionId,
      isAiChat: true,
      aiUser: aiUser,
    );
  }
}
