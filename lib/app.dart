import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/constants.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'widgets/in_app_notification.dart';
import 'widgets/banner_ad_widget.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_management_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/friends_list_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/media_folder_screen.dart';
import 'services/socket_service.dart';
import 'models/chat.dart'; // Added import for Chat model
import 'screens/chat_screen.dart'; // Added import for ChatScreen
import 'screens/random_chat_screen.dart'; // Added import for RandomChatScreen
import 'screens/test_interstitial_screen.dart';
import 'widgets/interstitial_ad_manager.dart';
import 'services/global_matching_service.dart';
import 'widgets/credits_display.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Utility function to navigate to chat from anywhere
void navigateToChatFromNotification(Map<String, dynamic> notificationData) {
  try {
    final senderId = notificationData['senderId'] ?? '';
    final senderName = notificationData['senderName'] ?? 'Unknown';
    final chatId = notificationData['chatId'] ?? '';

    // print('🔔 [NAVIGATION DEBUG] Navigating to chat from notification');
    // print('   👤 Sender ID: $senderId');
    // print('   👤 Sender Name: $senderName');
    // print('   💬 Chat ID: $chatId');

    if (senderId.isEmpty) {
      // print('❌ [NAVIGATION DEBUG] Sender ID is empty, cannot navigate to chat');
      return;
    }

    // Create a Chat object for friend chat
    final chat = Chat(
      id: chatId.isNotEmpty
          ? chatId
          : senderId, // Use senderId as chatId if chatId is empty
      name: senderName,
      participantIds: [senderId], // Add current user ID later
      type: ChatType.friend,
      status: ChatStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to chat screen using global navigator
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: chat),
      ),
    );

    // print('✅ [NAVIGATION DEBUG] Successfully navigated to chat screen');
  } catch (e) {
    // print('❌ [NAVIGATION DEBUG] Error navigating to chat: $e');
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return InterstitialAdManager(
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey, // Add global navigator key
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              themeMode:
                  themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
              routes: {
                '/home': (context) => const MainNavigationScreen(),
                '/profile': (context) => const ProfileScreen(),
                '/profile-management': (context) =>
                    const ProfileManagementScreen(),
                '/account-settings': (context) => const AccountSettingsScreen(),
                '/connect': (context) => const ConnectScreen(),
                '/login': (context) => const LoginScreen(),
                '/search': (context) => const SearchScreen(),
                '/friend-requests': (context) => const FriendRequestsScreen(),
                '/friends': (context) => const FriendsScreen(),
                '/chat-list': (context) => const ChatListScreen(),
                '/friends-list': (context) => const FriendsListScreen(),
                '/test-interstitial': (context) =>
                    const TestInterstitialScreen(),
                '/random-chat': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  if (args != null) {
                    final sessionId = args['sessionId'] as String?;
                    final chatRoomId = args['chatRoomId'] as String?;
                    if (sessionId != null && chatRoomId != null) {
                      return RandomChatScreen(
                        sessionId: sessionId,
                        chatRoomId: chatRoomId,
                      );
                    }
                  }
                  // Fallback for debugging
                  return const Scaffold(
                    body: Center(
                      child: Text('Invalid session data provided'),
                    ),
                  );
                },
                '/user-profile': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  if (args is String) {
                    return UserProfileScreen(userId: args);
                  }
                  // Fallback for debugging
                  return const Scaffold(
                    body: Center(
                      child: Text('Invalid user ID provided'),
                    ),
                  );
                },
              },
            ),
          );
        },
      ),
    );
  }
}


// Theme building methods
ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.cardBackground,
      background: AppColors.background,
      onSurface: AppColors.text,
      onBackground: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      tertiary: AppColors.darkAccent,
      surface: AppColors.darkCardBackground,
      background: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      onBackground: AppColors.darkText,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.darkCardBackground,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
    ),
  );
}

// Helper function to get AppBar theme for specific screens
AppBarTheme getAppBarThemeForScreen(String screenName) {
  switch (screenName) {
    case 'friend_requests':
    case 'search':
    case 'profile_management':
    case 'user_profile':
    case 'chat':
    case 'friends':
    case 'connect':
      // Use violet background for these screens
      return const AppBarTheme(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.darkText,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    default:
      // Use default theme for main landing page and other screens
      return const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final SocketService _socketService = SocketService();
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _initializeSocketConnection();
    _enableScreenProtection();
    _setupInAppNotificationListener();
    _initializeAnimations();
    _initializeGlobalMatchingService();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const ChatListScreen(),
      const ConnectScreen(),
      const MediaFolderScreen(),
    ];
  }

  void _initializeAnimations() {
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _initializeGlobalMatchingService() {
    final globalMatchingService = GlobalMatchingService();
    globalMatchingService.initialize();
    globalMatchingService.loadUserInterests();
  }

  Future<void> _initializeSocketConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          // print(
          //     '🚀 [APP DEBUG] Initializing socket connection with Firebase token');
          await _socketService.connect(token);

          // Send join event after connection
          await Future.delayed(const Duration(seconds: 1));
          // print('✅ [APP DEBUG] Socket connection completed');
        } else {
          // print('❌ [APP DEBUG] Failed to get Firebase token');
        }
      } else {
        // print('❌ [APP DEBUG] No Firebase user found, cannot connect socket');
      }
    } catch (e) {
      // print('❌ [APP DEBUG] Socket connection failed: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      // print('✅ [APP DEBUG] Notifications initialized');
    } catch (e) {
      // print('❌ [APP DEBUG] Failed to initialize notifications: $e');
    }
  }

  void _setupInAppNotificationListener() {
    // print('🔔 [APP DEBUG] Setting up in-app notification listener');

    _notificationService.inAppNotificationStream.listen(
      (notificationData) {
        // print('🔔 [APP DEBUG] *** NOTIFICATION RECEIVED IN STREAM ***');
        // print('   📦 Notification data: $notificationData');
        // print('   📱 Widget mounted: $mounted');

        // Check if user is currently in a chat with the sender
        final senderId = notificationData['senderId'] ?? '';
        final currentChatUserId = _socketService.currentChatWithUserId;

        // print('   👤 Sender ID: $senderId');
        // print('   👤 Current chat user: $currentChatUserId');

        if (currentChatUserId == senderId) {
          // print('🔔 [APP DEBUG] Skipping notification - user is in chat with sender');
          return;
        }

        if (mounted) {
          // print('🔔 [APP DEBUG] Showing in-app notification widget');

          showInAppNotification(
            context: context,
            senderName: notificationData['senderName'] ?? 'Unknown',
            message: notificationData['message'] ?? 'New message',
            senderId: senderId,
            chatId: notificationData['chatId'],
            onTap: () {
              // print('🔔 [APP DEBUG] In-app notification tapped');
              navigateToChatFromNotification(notificationData);
            },
          );

          // print('✅ [APP DEBUG] showInAppNotification called');
        } else {
          // print('❌ [APP DEBUG] Widget not mounted, cannot show notification');
        }
      },
      onError: (error) {
        // print('❌ [APP DEBUG] Error in notification stream: $error');
      },
      onDone: () {
        // print('🔔 [APP DEBUG] Notification stream closed');
      },
    );

    // print('✅ [APP DEBUG] In-app notification listener setup complete');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _drawerAnimationController.dispose();
    _socketService.disconnect();
    _disableScreenProtection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _enableScreenProtection();
        _notificationService.setAppForegroundState(true);
        // print('🔔 [APP DEBUG] App resumed - foreground notifications enabled');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Keep security features active even when app is paused/inactive
        _notificationService.setAppForegroundState(false);
        // print('🔔 [APP DEBUG] App paused/inactive - background notifications enabled');
        break;
      case AppLifecycleState.detached:
        _disableScreenProtection();
        _notificationService.setAppForegroundState(false);
        break;
      default:
        break;
    }
  }

  Future<void> _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      // print('🔒 Screen protection enabled');
    } catch (e) {
      // print('⚠️ Failed to enable screen protection: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      // print('🔓 Screen protection disabled');
    } catch (e) {
      // print('⚠️ Failed to disable screen protection: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToChatFromNotification(Map<String, dynamic> notificationData) {
    try {
      final senderId = notificationData['senderId'] ?? '';
      final senderName = notificationData['senderName'] ?? 'Unknown';
      final chatId = notificationData['chatId'] ?? '';

      // print('🔔 [APP DEBUG] Navigating to chat from notification');
      // print('   👤 Sender ID: $senderId');
      // print('   👤 Sender Name: $senderName');
      // print('   💬 Chat ID: $chatId');

      if (senderId.isEmpty) {
        // print('❌ [APP DEBUG] Sender ID is empty, cannot navigate to chat');
        return;
      }

      // Create a Chat object for friend chat
      final chat = Chat(
        id: chatId.isNotEmpty
            ? chatId
            : senderId, // Use senderId as chatId if chatId is empty
        name: senderName,
        participantIds: [senderId], // Add current user ID later
        type: ChatType.friend,
        status: ChatStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );

      // print('✅ [APP DEBUG] Successfully navigated to chat screen');
    } catch (e) {
      // print('❌ [APP DEBUG] Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 40),
                children: [
                  // Main Navigation
                  _buildDrawerSection(
                    context,
                    'Main Navigation',
                    [
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.home,
                        title: AppStrings.home,
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(0);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.chat,
                        title: AppStrings.chats,
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(1);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.connect,
                        title: AppStrings.connect,
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(2);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.media,
                        title: AppStrings.media,
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(3);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick Actions
                  _buildDrawerSection(
                    context,
                    'Quick Actions',
                    [
                      _buildDrawerItem(
                        context,
                        icon: Icons.search,
                        title: 'Find People',
                        subtitle: 'Search and connect with new people',
                        iconColor: theme.colorScheme.tertiary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/search');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.people,
                        title: 'Friend Requests',
                        subtitle: 'Manage your friend requests',
                        iconColor: theme.colorScheme.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/friend-requests');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.favorite,
                        title: 'Friends Section',
                        subtitle: 'View and manage your friends',
                        iconColor: theme.colorScheme.tertiary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/friends-list');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.history,
                        title: 'Your Activity',
                        subtitle: 'View your recent activity',
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _showActivityDialog(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Settings
                  _buildDrawerSection(
                    context,
                    'Settings',
                    [
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.profile,
                        title: AppStrings.profile,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToProfile();
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.settings,
                        title: AppStrings.settings,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/account-settings');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: AppIcons.logout,
                        title: AppStrings.logout,
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implement logout logic
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Banner Ad at the bottom
            const BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(bottom: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          _drawerAnimationController.reverse();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Your Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(Icons.person_add, color: theme.colorScheme.primary),
                title: const Text('Added a new friend'),
                subtitle: const Text('2 hours ago'),
              ),
              ListTile(
                leading:
                    Icon(Icons.message, color: theme.colorScheme.secondary),
                title: const Text('Sent a message'),
                subtitle: const Text('1 hour ago'),
              ),
              ListTile(
                leading: Icon(Icons.search, color: theme.colorScheme.tertiary),
                title: const Text('Searched for people'),
                subtitle: const Text('3 hours ago'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.transparent,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: AnimatedBuilder(
                    animation: _drawerAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _drawerAnimation.value * 0.5,
                        child: Icon(
                          Icons.menu,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      );
                    },
                  ),
                  onPressed: () {
                    _drawerAnimationController.forward();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  tooltip: 'Menu',
                ),
                title: Text(
                  'Chatify',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
                actions: [
                  // Credits Display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: CreditsDisplaySmall(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    onPressed: _navigateToProfile,
                    tooltip: 'Profile',
                  ),
                ],
                centerTitle: true,
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          _drawerAnimationController.reverse();
        }
      },
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.transparent,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedIconTheme: IconThemeData(
                color: const Color(0xFFE0B0FF).withOpacity(0.85),
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.55),
              ),
              selectedItemColor: const Color(0xFFE0B0FF).withOpacity(0.85),
              unselectedItemColor: Colors.white.withOpacity(0.55),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.home),
                  label: AppStrings.home,
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.chat),
                  label: AppStrings.chats,
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.connect),
                  label: AppStrings.connect,
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.media),
                  label: AppStrings.media,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
