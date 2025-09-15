import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/skeleton_list.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';
import '../core/theme_extensions.dart';
import '../core/constants.dart';
import 'random_chat_screen.dart';
import 'connect/connect_state_manager.dart';
import 'connect/connect_ui_components.dart';
import 'connect/connect_dialog_components.dart';
import 'connect/connect_filter_components.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late ConnectStateManager _stateManager;
  bool _isLoading = true;
  bool _showRadiusSelection = false;

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
      // Avoid triggering rebuilds after dispose
      onStateChanged: () {
        if (!mounted) return;
        setState(() {});
      },
      onNavigateToChat: _navigateToRandomChat,
      onShowTimeoutDialog: () =>
          ConnectDialogComponents.showTimeoutDialog(context, _stateManager),
      onShowWarningSnackBar: (message, color) =>
          ConnectDialogComponents.showWarningSnackBar(context, message, color),
      onShowClearSessionDialog: () =>
          ConnectDialogComponents.showClearSessionDialog(
              context, _stateManager),
    );
  }

  void _setupStateManager() {
    _stateManager.initializeServices();
    _stateManager.initializeAnimations(this);
    _stateManager.initializeFilters();
    _stateManager.setupSocketListeners();
    _stateManager.loadUserInterests();
    
    // Performance Note: Currently using setState() for all state changes.
    // Future optimization: Consider exposing granular ValueNotifiers/Selectors from state manager
    // and rebuilding only dependent subtrees (e.g., the match button) via ValueListenableBuilder
    // to reduce unnecessary widget rebuilds and improve performance.
  }

  Future<void> _loadContent() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  void _navigateToRandomChat(String sessionId, String chatRoomId) {
    // This method is used as a callback for ConnectStateManager
    // For direct navigation, use _navigateToRandomChatDirect
  }

  void _navigateToRandomChatDirect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RandomChatScreen(
          sessionId: 'demo_session',
          chatRoomId: 'demo_chat_room',
        ),
      ),
    );
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
    // Show matching screen if currently matching
    if (_stateManager.isMatching) {
      return ConnectUIComponents.buildMatchingScreen(context, _stateManager);
    }

    // Show radius selection if user clicked connect
    if (_showRadiusSelection) {
      return _buildRadiusSelection(context);
    }

    // Show hero section by default
    return _buildHeroSection(context);
  }

  Widget _buildHeroSection(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Image
            Container(
              width: 250,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/Girl.png'),
                  fit: BoxFit.contain,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Main Question
            const Text(
              'Ready to meet new people?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 30),
            
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    setState(() {
                      _showRadiusSelection = true;
                    });
                  },
                  child: const Center(
                    child: Text(
                      'Connect Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tagline
            const Text(
              'Find and chat with people around the world',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSelection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showRadiusSelection = false;
                  });
                },
              ),
              const Text(
                'Select Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Distance selection
          ConnectFilterComponents.buildDistanceFilter(context, _stateManager),
          
          const SizedBox(height: 40),
          
          // Start Matching Button
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
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  _stateManager.startMatching();
                },
                child: const Center(
                  child: Text(
                    'Start Matching',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
