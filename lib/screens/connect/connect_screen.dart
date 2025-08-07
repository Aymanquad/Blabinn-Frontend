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
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      onNavigateToChat: _navigateToRandomChat, // This is no longer used but kept for compatibility
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
    // Navigation is now handled by the global matching service
    // This method is kept for backward compatibility but is no longer used
  }

  @override
  Widget build(BuildContext context) {
    return ConnectUIComponents.buildMainScaffold(context, _stateManager);
  }
} 