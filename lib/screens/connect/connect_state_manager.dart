import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/premium_service.dart';
import '../../services/global_matching_service.dart';

class ConnectStateManager {
  // Use global matching service
  final GlobalMatchingService globalMatchingService = GlobalMatchingService();
  
  // Local state for UI
  bool isMatching = false;
  bool isConnected = false;
  Map<String, dynamic> filters = {};
  bool isPremium = false;
  String? currentSessionId;
  String? matchMessage;
  int queueTime = 0;
  String genderPreference = 'any';
  
  late ApiService apiService;
  late SocketService socketService;
  late StreamSubscription matchSubscription;
  late StreamSubscription errorSubscription;
  late AnimationController animationController;
  late Animation<double> scaleAnimation;

  // Callbacks for state changes
  final VoidCallback onStateChanged;
  final Function(String, String) onNavigateToChat; // No longer used but kept for compatibility
  final VoidCallback onShowTimeoutDialog;
  final Function(String, Color) onShowWarningSnackBar;
  final VoidCallback onShowClearSessionDialog;

  ConnectStateManager({
    required this.onStateChanged,
    required this.onNavigateToChat,
    required this.onShowTimeoutDialog,
    required this.onShowWarningSnackBar,
    required this.onShowClearSessionDialog,
  });

  void initializeServices() {
    apiService = ApiService();
    socketService = SocketService();
    
    // Sync with global matching service
    _syncWithGlobalService();
    _setupGlobalServiceListeners();
  }

  void initializeAnimations(TickerProvider vsync) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    );
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    );
    animationController.forward();
  }

  void initializeFilters() {
    filters = {
      'distance': '1-5',
      'language': 'any',
      'ageRange': 'all',
      'interests': [],
    };
    genderPreference = 'any';
  }

  void _syncWithGlobalService() {
    isMatching = globalMatchingService.isMatching;
    isConnected = globalMatchingService.isConnected;
    currentSessionId = globalMatchingService.currentSessionId;
    matchMessage = globalMatchingService.matchMessage;
    queueTime = globalMatchingService.queueTime;
    genderPreference = globalMatchingService.genderPreference;
    filters = globalMatchingService.filters;
  }

  void _setupGlobalServiceListeners() {
    globalMatchingService.matchingStateStream.listen((matching) {
      isMatching = matching;
      onStateChanged();
    });

    globalMatchingService.connectionStateStream.listen((connected) {
      isConnected = connected;
      onStateChanged();
    });

    globalMatchingService.messageStream.listen((message) {
      matchMessage = message;
      onStateChanged();
    });

    globalMatchingService.queueTimeStream.listen((time) {
      queueTime = time;
      onStateChanged();
    });
  }

  Future<void> loadUserInterests() async {
    try {
      final currentUserId = await apiService.getCurrentUserId();
      if (currentUserId == null) {
        return;
      }

      final profileData = await apiService.getUserProfile(currentUserId);
      final userInterests = profileData['interests'];

      if (userInterests != null && userInterests is List) {
        filters['interests'] = List<String>.from(userInterests);
        onStateChanged();
      }
    } catch (e) {
      // Keep default empty interests array if loading fails
    }
  }

  void setupSocketListeners() {
    // Socket listeners are now handled by the global matching service
    // This method is kept for backward compatibility but is no longer needed
  }

  void cleanupSocketListeners() {
    // Socket listeners are now handled by the global matching service
    // This method is kept for backward compatibility but is no longer needed
  }

  void handleMatchEvent(Map<String, dynamic> data) {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  void handleErrorEvent(String error) {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  void handleError(String error) {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  Future<void> clearActiveSession() async {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  void handleRandomChatEvent(Map<String, dynamic> data) {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  void handleRandomChatTimeout() {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  Future<void> startMatching() async {
    if (isMatching || isConnected) {
      return;
    }

    try {
      // Update global service filters and preferences
      globalMatchingService.setFilters(filters);
      globalMatchingService.setGenderPreference(genderPreference);
      
      // Start matching using global service
      await globalMatchingService.startMatching();
    } catch (e) {
      isMatching = false;
      matchMessage = 'Error: ${e.toString()}';
      onStateChanged();
    }
  }

  void startQueueTimer() {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  Future<void> stopMatching() async {
    if (!isMatching && !isConnected) return;

    try {
      // Stop matching using global service
      await globalMatchingService.stopMatching();
    } catch (e) {
      // Handle error
    }
  }

  void handleImmediateMatch(Map<String, dynamic> connection) {
    // This method is now handled by the global matching service
    // Kept for backward compatibility
  }

  void dispose() {
    // Socket listeners are now handled by the global matching service
    // Only dispose animation controller
    animationController.dispose();
  }
} 