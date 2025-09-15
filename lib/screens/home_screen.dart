import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/skeleton_list.dart';
import '../core/theme_extensions.dart';
import '../core/constants.dart';
import 'random_chat_screen.dart';
import 'connect/connect_state_manager.dart';
import 'connect/connect_ui_components.dart';
import 'connect/connect_dialog_components.dart';

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
  List<Map<String, dynamic>> _quickActions = [];

  @override
  void initState() {
    super.initState();
    _initializeStateManager();
    _setupStateManager();
    // Defer non-critical work until after first frame to improve startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuickActions();
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

  Future<void> _loadQuickActions() async {
    // Simulate loading quick actions
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoading = false;
      _quickActions = [
        {
          'title': 'Random Chat',
          'subtitle': 'Start a new conversation',
          'icon': Icons.chat_bubble_outline,
          'color': Colors.blue,
          'onTap': _navigateToRandomChatDirect,
        },
        {
          'title': 'Find Friends',
          'subtitle': 'Discover new people',
          'icon': Icons.people_outline,
          'color': Colors.green,
          'onTap': () =>
              widget.onNavigateToTab?.call(1), // Navigate to Connect tab
        },
      ];
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
        child: Column(
          children: [
            // Enhanced Header Section
            // Isolate static header paints from dynamic content
            RepaintBoundary(child: _buildHeader(context, tokens)),

            // Main Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(context, tokens)
                  : _buildMainContent(context, tokens),
            ),

            // Bottom Section with Connect Button and Ad
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeTokens? tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Welcome Text
          Text(
            'Welcome to Chatify',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect, chat, and make new friends',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppThemeTokens? tokens) {
    return SkeletonList(
      itemCount: 4,
      itemBuilder: (context, index) => GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SkeletonItem(
          height: 80,
          borderRadius: BorderRadius.circular(tokens?.radiusMedium ?? 16.0),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AppThemeTokens? tokens) {
    if (_stateManager.isMatching) {
      return ConnectUIComponents.buildMatchingScreen(context, _stateManager);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Section
          _buildQuickActionsSection(context, tokens),

          const SizedBox(height: 24),

          // Recent Activity Section
          // Static, unlikely to change frequently – isolate paints
          RepaintBoundary(child: _buildRecentActivitySection(context, tokens)),

          const SizedBox(height: 24),

          // Tips Section
          // Static tips – isolate paints
          RepaintBoundary(child: _buildTipsSection(context, tokens)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, AppThemeTokens? tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Keep 2-column grid for the remaining two actions
            const crossAxisCount = 2;
            // Adjust aspect ratio to prevent overflow - make cards taller
            const childAspectRatio = 0.85;

            return RepaintBoundary(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _quickActions.length,
                itemBuilder: (context, index) {
                  final action = _quickActions[index];
                  return _buildQuickActionCard(context, action, tokens);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context,
      Map<String, dynamic> action, AppThemeTokens? tokens) {
    return GlassCard(
      onTap: action['onTap'],
      child: Semantics(
        label: '${action['title']} - ${action['subtitle']}',
        button: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action['icon'],
                  color: action['color'],
                  size: 28,
                  semanticLabel: action['title'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['title'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 4),
              Text(
                action['subtitle'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(
      BuildContext context, AppThemeTokens? tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: AppColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No recent activity',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Start chatting to see your activity here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context, AppThemeTokens? tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips for Better Connections',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipItem(
                  context,
                  Icons.verified_user,
                  'Complete your profile',
                  'Add photos and interests to get more matches',
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  context,
                  Icons.location_on,
                  'Set your location',
                  'Enable location to find people nearby',
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  context,
                  Icons.chat_bubble,
                  'Start conversations',
                  'Be friendly and respectful in your messages',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(
      BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Connect Button
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: _stateManager.isMatching
                  ? 'Stop matching with people'
                  : 'Start matching with people',
              button: true,
              child: ElevatedButton(
                onPressed: _stateManager.isMatching
                    ? _stateManager.stopMatching
                    : _stateManager.startMatching,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _stateManager.isMatching ? Colors.red : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _stateManager.isMatching ? 'Stop Matching' : 'Start Matching',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Banner Ad
          // Ads can be expensive to repaint; isolate them
          const RepaintBoundary(
            child: BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(bottom: 8),
            ),
          ),
        ],
      ),
    );
  }
}
