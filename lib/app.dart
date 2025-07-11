import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'providers/theme_provider.dart';
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
import 'services/socket_service.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final SocketService _socketService = SocketService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    _screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const ChatListScreen(),
      const ConnectScreen(),
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

  @override
  void dispose() {
    _pageController.dispose();
    _socketService.disconnect();
    super.dispose();
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
          ],
        ),
      ),
    );
  }
}
