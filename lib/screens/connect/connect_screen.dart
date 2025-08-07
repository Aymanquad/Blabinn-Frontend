import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/premium_service.dart';
import '../../models/user.dart';
import '../../widgets/banner_ad_widget.dart';
import 'dart:convert';
import '../random_chat_screen.dart';
import 'connect_state_manager.dart';
import 'connect_ui_components.dart';
import 'connect_dialog_components.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late ConnectStateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _initializeStateManager();
    _setupStateManager();
  }

  void _initializeStateManager() {
    _stateManager = ConnectStateManager(
      onStateChanged: () => setState(() {}),
      onNavigateToChat: _navigateToRandomChat,
      onShowTimeoutDialog: () => ConnectDialogComponents.showTimeoutDialog(context, _stateManager),
      onShowWarningSnackBar: (message, color) => ConnectDialogComponents.showWarningSnackBar(context, message, color),
      onShowClearSessionDialog: () => ConnectDialogComponents.showClearSessionDialog(context, _stateManager),
    );
  }

  void _setupStateManager() {
    _stateManager.initializeServices();
    _stateManager.initializeAnimations(this);
    _stateManager.initializeFilters();
    _stateManager.setupSocketListeners();
    _stateManager.loadUserInterests();
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  void _navigateToRandomChat(String sessionId, String chatRoomId) {
    try {
      print('🚀 [CONNECT DEBUG] Navigating to random chat');
      print('   📱 Session ID: $sessionId');
      print('   💬 Chat Room ID: $chatRoomId');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return RandomChatScreen(
              sessionId: sessionId,
              chatRoomId: chatRoomId,
            );
          },
        ),
      ).then((_) {
        print('🔙 [CONNECT DEBUG] Returned from RandomChatScreen, resetting state');
        // When returning from random chat, reset state
        setState(() {
          _stateManager.isMatching = false;
          _stateManager.isConnected = false;
          _stateManager.currentSessionId = null;
          _stateManager.matchMessage = null;
        });
      }).catchError((error) {
        print('❌ [CONNECT DEBUG] Navigation error: $error');
        // Handle navigation error
        setState(() {
          _stateManager.isMatching = false;
          _stateManager.isConnected = false;
          _stateManager.currentSessionId = null;
          _stateManager.matchMessage = 'Navigation error. Please try again.';
        });
      });
    } catch (e) {
      print('❌ [CONNECT DEBUG] Error during navigation: $e');
      setState(() {
        _stateManager.isMatching = false;
        _stateManager.isConnected = false;
        _stateManager.currentSessionId = null;
        _stateManager.matchMessage = 'Error starting chat. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectUIComponents.buildMainScaffold(context, _stateManager);
  }
} 