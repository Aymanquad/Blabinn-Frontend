import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/splash_screen.dart';
import 'models/chat.dart';
import 'core/constants.dart';

void main() {
  runApp(const ScreenTesterApp());
}

class ScreenTesterApp extends StatelessWidget {
  const ScreenTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Tester',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScreenSelector(),
    );
  }
}

class ScreenSelector extends StatelessWidget {
  const ScreenSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Tester'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a screen to test:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildScreenButton(
              context,
              'Splash Screen',
              'App launch screen with logo animation',
              Icons.auto_awesome,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Home Screen',
              'Main navigation screen with tabs',
              Icons.home,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Connect Screen',
              'Find and match with new people',
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConnectScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Chat Screen',
              'Chat interface with sample user',
              Icons.chat,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chat: Chat(
                      id: 'test-chat',
                      name: 'Test User',
                      participantIds: ['user1', 'user2'],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      unreadCount: 3,
                      isTyping: false,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Profile Screen',
              'User profile and settings',
              Icons.person,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Video Call Screen',
              'Video calling interface',
              Icons.videocam,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoCallScreen(
                    callId: 'test-call',
                    remoteUserId: 'test-user',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }
} 