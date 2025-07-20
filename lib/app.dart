import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/constants.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'widgets/in_app_notification.dart';
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
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> 
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final SocketService _socketService = SocketService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _initializeSocketConnection();
    _enableScreenProtection();
    _setupInAppNotificationListener();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const ChatListScreen(),
      const ConnectScreen(),
      const MediaFolderScreen(),
    ];
  }

  Future<void> _initializeSocketConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          print(
              '🚀 [APP DEBUG] Initializing socket connection with Firebase token');
          await _socketService.connect(token);

          // Send join event after connection
          await Future.delayed(const Duration(seconds: 1));
          print('✅ [APP DEBUG] Socket connection completed');
        } else {
          print('❌ [APP DEBUG] Failed to get Firebase token');
        }
      } else {
        print('❌ [APP DEBUG] No Firebase user found, cannot connect socket');
      }
    } catch (e) {
      print('❌ [APP DEBUG] Socket connection failed: $e');
    }
  }
  
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      print('✅ [APP DEBUG] Notifications initialized');
    } catch (e) {
      print('❌ [APP DEBUG] Failed to initialize notifications: $e');
    }
  }
  
  void _setupInAppNotificationListener() {
    print('🔔 [APP DEBUG] Setting up in-app notification listener');
    
    _notificationService.inAppNotificationStream.listen(
      (notificationData) {
        print('🔔 [APP DEBUG] *** NOTIFICATION RECEIVED IN STREAM ***');
        print('   📦 Notification data: $notificationData');
        print('   📱 Widget mounted: $mounted');
        
        if (mounted) {
          print('🔔 [APP DEBUG] Showing in-app notification widget');
          
          showInAppNotification(
            context: context,
            senderName: notificationData['senderName'] ?? 'Unknown',
            message: notificationData['message'] ?? 'New message',
            senderId: notificationData['senderId'] ?? '',
            chatId: notificationData['chatId'],
            onTap: () {
              print('🔔 [APP DEBUG] In-app notification tapped');
              // TODO: Navigate to chat screen
              // You can add navigation logic here
            },
          );
          
          print('✅ [APP DEBUG] showInAppNotification called');
        } else {
          print('❌ [APP DEBUG] Widget not mounted, cannot show notification');
        }
      },
      onError: (error) {
        print('❌ [APP DEBUG] Error in notification stream: $error');
      },
      onDone: () {
        print('🔔 [APP DEBUG] Notification stream closed');
      },
    );
    
    print('✅ [APP DEBUG] In-app notification listener setup complete');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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
        print('🔔 [APP DEBUG] App resumed - foreground notifications enabled');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Keep security features active even when app is paused/inactive
        _notificationService.setAppForegroundState(false);
        print('🔔 [APP DEBUG] App paused/inactive - background notifications enabled');
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
      print('🔒 Screen protection enabled');
    } catch (e) {
      print('⚠️ Failed to enable screen protection: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      print('🔓 Screen protection disabled');
    } catch (e) {
      print('⚠️ Failed to disable screen protection: $e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          // Test notification button (temporary)
          IconButton(
            icon: Icon(
              Icons.notifications_active,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              print('🔔 [TEST] Test notification button pressed');
              _notificationService.testNotification();
            },
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: Icon(
              AppIcons.profile,
              color: theme.colorScheme.primary,
            ),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
    );
  }
}
