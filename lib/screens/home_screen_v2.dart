import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/skeleton_list.dart';
import '../core/theme_extensions.dart';
import '../core/constants.dart';
import '../state/state_selector.dart';
import '../state/state_manager.dart';
import 'random_chat_screen.dart';
import 'connect/connect_ui_components.dart';

/// Optimized home screen using granular state management
class HomeScreenV2 extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreenV2({super.key, this.onNavigateToTab});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final StateManager _stateManager = StateManager();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuickActions();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadQuickActions() async {
    // Simulate loading quick actions
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header Section - Only rebuilds when user data changes
              UserSelector(
                builder: (context, user) => _buildHeader(context, tokens, user),
              ),

              // Main Content - Only rebuilds when matching status changes
              Expanded(
                child: MatchingSelector(
                  builder: (context, isMatching) {
                    if (isMatching) {
                      return _buildMatchingContent(context);
                    }
                    return _buildMainContent(context, tokens);
                  },
                ),
              ),

              // Bottom Section - Only rebuilds when connection status changes
              ConnectionSelector(
                builder: (context, isConnected) => _buildBottomSection(context, isConnected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeTokens? tokens, User? user) {
    return RepaintBoundary(
      child: Container(
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
      ),
    );
  }

  Widget _buildMatchingContent(BuildContext context) {
    return MatchingSelector(
      builder: (context, isMatching) {
        return ConnectUIComponents.buildMatchingScreen(
          context,
          null, // We'll need to adapt this to work with the new state system
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, AppThemeTokens? tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Section
          _buildQuickActionsSection(context, tokens),

          const SizedBox(height: 24),

          // Recent Activity Section - Only rebuilds when chats change
          ChatsSelector(
            builder: (context, chats) => _buildRecentActivitySection(context, chats),
          ),

          const SizedBox(height: 24),

          // Stats Section - Only rebuilds when user data changes
          UserSelector(
            builder: (context, user) => _buildStatsSection(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppThemeTokens? tokens) {
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
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Random Chat',
                subtitle: 'Start a new conversation',
                icon: Icons.chat_bubble_outline,
                color: Colors.blue,
                onTap: _navigateToRandomChatDirect,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Find Friends',
                subtitle: 'Discover new people',
                icon: Icons.people_outline,
                color: Colors.green,
                onTap: () => widget.onNavigateToTab?.call(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, List<Chat> chats) {
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
        if (chats.isEmpty)
          _buildEmptyState(context)
        else
          _buildChatsList(context, chats),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent chats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation to see your chats here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList(BuildContext context, List<Chat> chats) {
    return Column(
      children: chats.take(3).map((chat) => _buildChatItem(context, chat)).toList(),
    );
  }

  Widget _buildChatItem(BuildContext context, Chat chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          title: Text(
            'Chat ${chat.id.substring(0, 8)}',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            chat.lastMessage?.content ?? 'No messages yet',
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: chat.unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () {
            // Navigate to chat
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Credits',
                value: user?.credits.toString() ?? '0',
                icon: Icons.stars,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Friends',
                value: user?.friendsCount.toString() ?? '0',
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Connect Button - Only rebuilds when connection status changes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isConnected ? _stateManager.startMatching : null,
              icon: const Icon(Icons.search),
              label: Text(isConnected ? 'Start Matching' : 'Connecting...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Banner Ad
          const BannerAdWidget(
            height: 50,
            margin: EdgeInsets.only(bottom: 8),
          ),
        ],
      ),
    );
  }
}
