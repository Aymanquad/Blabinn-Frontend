import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'widgets/modern_glass_nav_bar.dart' as modern_nav;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/constants.dart';
import 'core/theme_extensions.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'widgets/in_app_notification.dart';
import 'widgets/banner_ad_widget.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_management_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/profile_preview_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/friends_list_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/likes_matches_screen.dart';
import 'services/socket_service.dart';
import 'models/chat.dart'; // Added import for Chat model
import 'screens/chat_screen.dart'; // Added import for ChatScreen
import 'screens/random_chat_screen.dart'; // Added import for RandomChatScreen
import 'screens/test_interstitial_screen.dart';
import 'widgets/interstitial_ad_manager.dart';
import 'services/global_matching_service.dart';
import 'widgets/credits_display.dart';
import 'screens/credit_shop_screen.dart';
import 'services/api_service.dart';
import 'widgets/modern_navigation_bar.dart';
import 'widgets/enhanced_background.dart';
import 'utils/logger.dart';
import 'navigation/credit_shop_route.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Utility function to navigate to chat from anywhere
void navigateToChatFromNotification(Map<String, dynamic> notificationData) {
  try {
    final senderId = notificationData['senderId'] ?? '';
    final senderName = notificationData['senderName'] ?? 'Unknown';
    final chatId = notificationData['chatId'] ?? '';

    Logger.notification('Navigating to chat from notification');
    Logger.debug('Sender ID: $senderId');
    Logger.debug('Sender Name: $senderName');
    Logger.debug('Chat ID: $chatId');

    if (senderId.isEmpty) {
      Logger.warning('Sender ID is empty, cannot navigate to chat');
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

    Logger.notification('Successfully navigated to chat screen');
  } catch (e) {
    Logger.error('Error navigating to chat', error: e);
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return InterstitialAdManager(
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey, // Add global navigator key
              theme: _buildDarkTheme(),
              themeMode: ThemeMode.dark,
              home: const SplashScreen(),
              builder: (context, child) =>
                  EnhancedBackground(child: child ?? const SizedBox()),
              routes: {
                '/home': (context) => const MainNavigationScreen(),
                '/profile': (context) => const ProfileScreen(),
                '/profile-management': (context) =>
                    const ProfileManagementScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/account-settings': (context) => const AccountSettingsScreen(),
                '/connect': (context) => const ConnectScreen(),
                '/login': (context) => const LoginScreen(),
                '/search': (context) => const SearchScreen(),
                '/friend-requests': (context) => const FriendRequestsScreen(),
                '/friends': (context) => const FriendsScreen(),
                '/chat-list': (context) => const ChatListScreen(),
                '/friends-list': (context) => const FriendsListScreen(),
                '/profile-preview': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  if (args is Map<String, dynamic>) {
                    return ProfilePreviewScreen(
                      userId: args['userId'] as String?,
                      initialUserData:
                          args['initialUserData'] as Map<String, dynamic>?,
                    );
                  }
                  if (args is String) {
                    return ProfilePreviewScreen(userId: args);
                  }
                  return const ProfilePreviewScreen();
                },
                '/test-interstitial': (context) =>
                    const TestInterstitialScreen(),
                '/random-chat': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
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

// Theme building method - Dark mode only

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.cardBackground,
      background: AppColors.background,
      onSurface: AppColors.text,
      onBackground: AppColors.text,
    ),
    scaffoldBackgroundColor: Colors.transparent,

    // Enhanced TextTheme with consistent hierarchy
    fontFamily: 'LeagueSpartan',
    textTheme: const TextTheme(
      // Display styles for hero text and main headings
      displayLarge: TextStyle(
        fontSize: 36, // Increased size
        fontWeight: FontWeight.w900, // Maximum weight for main headlines
        color: Colors.white, // Pure white for maximum contrast
        letterSpacing: -0.5,
        fontFamily: 'LeagueSpartan',
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 32, // Increased size
        fontWeight: FontWeight.w800, // Extra bold for secondary headlines
        color: Colors.white,
        letterSpacing: -0.25,
        fontFamily: 'LeagueSpartan',
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontSize: 28, // Increased size
        fontWeight: FontWeight.w800, // Extra bold for tertiary headlines
        color: Colors.white,
        letterSpacing: 0,
        fontFamily: 'LeagueSpartan',
        height: 1.3,
      ),

      // Title styles for section headers
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: 0,
        fontFamily: 'LeagueSpartan',
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: 0.15,
        fontFamily: 'LeagueSpartan',
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        fontFamily: 'LeagueSpartan',
        letterSpacing: 0.1,
      ),

      // Body styles for content
      bodyLarge: TextStyle(
        fontSize: 18, // Increased size
        fontWeight: FontWeight.w700, // Bold for primary content
        color: Colors.white, // Pure white for better contrast
        letterSpacing: 0.5,
        fontFamily: 'LeagueSpartan',
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 16, // Increased size
        fontWeight: FontWeight.w600, // Semi-bold for regular text
        color: const Color(0xF2FFFFFF), // White with 95% opacity
        letterSpacing: 0.25,
        fontFamily: 'LeagueSpartan',
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 14, // Increased size
        fontWeight: FontWeight.w600, // Semi-bold for small text
        color: const Color(0xE6FFFFFF), // White with 90% opacity
        letterSpacing: 0.4,
        fontFamily: 'LeagueSpartan',
        height: 1.4,
      ),

      // Label styles for buttons and inputs
      labelLarge: TextStyle(
        fontSize: 16, // Increased size
        fontWeight: FontWeight.w700, // Bold for buttons
        color: Colors.white,
        letterSpacing: 0.1,
        fontFamily: 'LeagueSpartan',
      ),
      labelMedium: TextStyle(
        fontSize: 14, // Increased size
        fontWeight: FontWeight.w600, // Semi-bold for medium labels
        color: const Color(0xF2FFFFFF), // White with 95% opacity
        letterSpacing: 0.5,
        fontFamily: 'LeagueSpartan',
      ),
      labelSmall: TextStyle(
        fontSize: 12, // Increased size
        fontWeight: FontWeight.w600, // Semi-bold for small labels
        color: const Color(0xE6FFFFFF), // White with 90% opacity
        letterSpacing: 0.5,
        fontFamily: 'LeagueSpartan',
      ),
    ),

    // Enhanced AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: 0.15,
      ),
      centerTitle: true,
    ),

    // Enhanced Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // Enhanced Card theme
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Enhanced Input theme
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    ),

    // Enhanced Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.inputBackground,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Enhanced Bottom Navigation theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    extensions: <ThemeExtension<dynamic>>[
      AppThemeTokens.instance,
    ],
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.text,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    default:
      // Use default theme for main landing page and other screens
      return const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
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
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);
  final SocketService _socketService = SocketService();
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _navLocked = false;

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
    _claimDailyCreditsIfNeeded();
    _syncCreditsOnStartup();
    _screens = [
      ConnectScreen(onNavigateToTab: _onTabTapped),
      const ChatListScreen(),
      HomeScreen(onNavigateToTab: _onTabTapped),
      const LikesMatchesScreen(),
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
          Logger.socket('Initializing socket connection with Firebase token');
          await _socketService.connect(token);

          // Send join event after connection
          await Future.delayed(const Duration(seconds: 1));
          Logger.socket('Socket connection completed');
        } else {
          Logger.warning('Failed to get Firebase token');
        }
      } else {
        Logger.warning('No Firebase user found, cannot connect socket');
      }
    } catch (e) {
      Logger.error('Socket connection failed', error: e);
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      Logger.notification('Notifications initialized');
    } catch (e) {
      Logger.error('Failed to initialize notifications', error: e);
    }
  }

  void _setupInAppNotificationListener() {
    Logger.notification('Setting up in-app notification listener');

    _notificationService.inAppNotificationStream.listen(
      (notificationData) {
        Logger.notification('Notification received in stream');
        Logger.debug('Notification data: $notificationData');
        Logger.debug('Widget mounted: $mounted');

        // Check if user is currently in a chat with the sender
        final senderId = notificationData['senderId'] ?? '';
        final currentChatUserId = _socketService.currentChatWithUserId;

        Logger.debug('Sender ID: $senderId');
        Logger.debug('Current chat user: $currentChatUserId');

        if (currentChatUserId == senderId) {
          Logger.notification(
              'Skipping notification - user is in chat with sender');
          return;
        }

        if (mounted) {
          Logger.notification('Showing in-app notification widget');

          showInAppNotification(
            context: context,
            senderName: notificationData['senderName'] ?? 'Unknown',
            message: notificationData['message'] ?? 'New message',
            senderId: senderId,
            chatId: notificationData['chatId'],
            onTap: () {
              Logger.notification('In-app notification tapped');
              navigateToChatFromNotification(notificationData);
            },
          );

          Logger.notification('showInAppNotification called');
        } else {
          Logger.warning('Widget not mounted, cannot show notification');
        }
      },
      onError: (error) {
        Logger.error('Error in notification stream', error: error);
      },
      onDone: () {
        Logger.notification('Notification stream closed');
      },
    );

    Logger.notification('In-app notification listener setup complete');
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
        Logger.notification('App resumed - foreground notifications enabled');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Keep security features active even when app is paused/inactive
        _notificationService.setAppForegroundState(false);
        Logger.notification(
            'App paused/inactive - background notifications enabled');
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
      Logger.info('Screen protection enabled');
    } catch (e) {
      Logger.warning('Failed to enable screen protection', error: e);
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      Logger.info('Screen protection disabled');
    } catch (e) {
      Logger.warning('Failed to disable screen protection', error: e);
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

  Future<void> _claimDailyCreditsIfNeeded() async {
    try {
      // Wait until first frame to ensure context/providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.currentUser == null) return;
        try {
          final api = ApiService();
          final result = await api.claimDailyCredits();
          final awarded = (result['awarded'] as int?) ?? 0;
          final credits =
              (result['credits'] as int?) ?? userProvider.currentUser!.credits;
          if (awarded > 0) {
            userProvider.updateCurrentUser(
                userProvider.currentUser!.copyWith(credits: credits));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Daily bonus: +$awarded credits'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _syncCreditsOnStartup() async {
    try {
      // Wait until first frame to ensure context/providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.currentUser != null) {
          await userProvider.refreshCredits();
        }
      });
    } catch (_) {}
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _navigateToCreditShop() async {
    // Prevent double-tap navigation: ignore subsequent taps for 400ms
    if (_navLocked) return;
    setState(() => _navLocked = true);

    try {
      await Navigator.of(context).push(
        CreditShopRoute<void>(builder: (_) => const CreditShopScreen()),
      );
    } finally {
      // Small delay to prevent double taps re-triggering during animation end
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _navLocked = false);
    }
  }

  // Removed unused duplicate navigation method

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1B2E),
              const Color(0xFF2A2A3E),
              const Color(0xFF1E1B2E).withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 60),
                children: [
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
                        iconColor: Theme.of(context).colorScheme.tertiary,
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
                        iconColor: Theme.of(context).colorScheme.secondary,
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
                        iconColor: Theme.of(context).colorScheme.tertiary,
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
                        iconColor: Theme.of(context).colorScheme.primary,
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
                          _showLogoutDialog(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.0,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          _drawerAnimationController.reverse();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (iconColor ?? const Color(0xFFA259FF)).withOpacity(0.3),
                      (iconColor ?? const Color(0xFFA259FF)).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (iconColor ?? const Color(0xFFA259FF)).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFFA259FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.6),
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

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context);
            },
            child: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      Logger.auth('User logging out');

      // Disconnect socket
      _socketService.disconnect();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      Logger.auth('Logout completed successfully');
    } catch (e) {
      Logger.error('Error during logout', error: e);
      // Show error message to user
      if (context.mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
                  // Show credits only on Home (index 2) - tap to open credit shop
                  if (_currentIndex == 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: CreditsDisplaySmall(
                          onTap: _navLocked ? null : _navigateToCreditShop,
                        ),
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      bottomNavigationBar: modern_nav.ModernGlassNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          modern_nav.NavigationBarItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
          ),
          modern_nav.NavigationBarItem(
            icon: Icons.visibility_outlined,
            label: 'Visibility',
          ),
          modern_nav.NavigationBarItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
          ),
          modern_nav.NavigationBarItem(
            icon: Icons.favorite_border,
            label: 'Likes',
          ),
        ],
      ),
    );
  }
}
