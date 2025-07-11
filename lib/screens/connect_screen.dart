import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/user.dart';
import 'dart:async';
import 'dart:convert';
import 'random_chat_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isMatching = false;
  bool _isConnected = false;
  Map<String, dynamic> _filters = {};
  bool _isPremium = false;
  String? _currentSessionId;
  String? _matchMessage;
  int _queueTime = 0;
  late ApiService _apiService;
  late SocketService _socketService;
  late StreamSubscription _matchSubscription;
  late StreamSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _initializeServices();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _cleanupSocketListeners();
    _stopMatching();
    super.dispose();
  }

  void _initializeServices() {
    _apiService = ApiService();
    _socketService = SocketService();
  }

  void _initializeFilters() {
    _filters = {
      'distance': '1-5',
      'language': 'any',
      'ageRange': 'all',
      'interests': [],
    };
  }

  void _setupSocketListeners() {
    // Listen for match events using the stream approach
    _matchSubscription = _socketService.matchStream.listen(_handleMatchEvent);
    _errorSubscription = _socketService.errorStream.listen(_handleErrorEvent);

    // Listen for random chat events
    _socketService.eventStream.listen((event) {
      if (event == SocketEvent.randomChatEvent) {
        print(
            '🎯 [CONNECT DEBUG] randomChatEvent detected, getting latest data...');
        final data = _socketService.latestRandomChatData;
        if (data != null) {
          print('🎯 [CONNECT DEBUG] Got latest random chat data: $data');
          _handleRandomChatEvent(data);
        } else {
          print('❌ [CONNECT DEBUG] No latest random chat data available');
        }
      } else if (event == SocketEvent.randomChatTimeout) {
        _handleRandomChatTimeout();
      }
    });
  }

  void _cleanupSocketListeners() {
    _matchSubscription.cancel();
    _errorSubscription.cancel();
  }

  void _handleMatchEvent(Map<String, dynamic> data) {
    if (!mounted) return;

    final event = data['event'];

    if (event == 'match_found') {
      final sessionId = data['sessionId'];
      final chatRoomId = data['chatRoomId'];

      setState(() {
        _currentSessionId = sessionId;
        _isMatching = false;
        _isConnected = true;
        _matchMessage = 'Match found! Starting chat...';
      });

      // Navigate to random chat screen
      _navigateToRandomChat(sessionId, chatRoomId);
    } else if (event == 'match_timeout') {
      setState(() {
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage =
            data['message'] ?? 'No match found. Please try again later.';
      });

      _showTimeoutDialog();
    }
  }

  void _handleErrorEvent(String error) {
    print('🎯 [CONNECT DEBUG] _handleErrorEvent called with: $error');
    if (!mounted) return;

    // Parse structured error data (format: message|code|sessionId|chatRoomId)
    String errorMessage = error;
    String errorCode = '';
    String sessionId = '';
    String chatRoomId = '';

    if (error.contains('|')) {
      final parts = error.split('|');
      if (parts.length >= 4) {
        errorMessage = parts[0];
        errorCode = parts[1];
        sessionId = parts[2];
        chatRoomId = parts[3];
        print('🔍 [CONNECT DEBUG] Parsed error data:');
        print('   📝 Message: $errorMessage');
        print('   🏷️ Code: $errorCode');
        print('   🆔 SessionId: $sessionId');
        print('   💬 ChatRoomId: $chatRoomId');
      }
    }

    // Handle specific error codes
    if (errorCode == 'ALREADY_IN_SESSION' ||
        errorMessage.contains('ALREADY_IN_SESSION')) {
      print('🟡 [CONNECT DEBUG] Handling ALREADY_IN_SESSION error');
      setState(() {
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = sessionId.isNotEmpty ? sessionId : null;
        _matchMessage = 'You already have an active chat session.';
      });
      _showWarningSnackBar(
          'You already have an active chat session.', Colors.orange);
      _showClearSessionDialog();
      return;
    } else if (errorCode == 'ALREADY_IN_QUEUE' ||
        errorMessage.contains('ALREADY_IN_QUEUE')) {
      print('🟡 [CONNECT DEBUG] Handling ALREADY_IN_QUEUE error');
      setState(() {
        _isMatching = true; // Keep matching state since user is in queue
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = 'You are already in the matching queue. Please wait...';
      });
      _showWarningSnackBar(
          'You are already in the matching queue. Please wait...', Colors.blue);
      return;
    }

    // Handle general errors
    print('🔴 [CONNECT DEBUG] Handling general error: $errorMessage');
    setState(() {
      _isMatching = false;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = 'Error: $errorMessage';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection error: $errorMessage'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _clearActiveSession() async {
    try {
      print('🧹 [CONNECT DEBUG] Clearing active session...');
      final result = await _apiService.forceClearActiveSession();
      print('✅ [CONNECT DEBUG] Session cleared: $result');

      setState(() {
        _isMatching = false;
        _isConnected = false;
        _currentSessionId = null;
        _matchMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Active session cleared. You can now start a new chat.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ [CONNECT DEBUG] Failed to clear session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Active Session Found'),
          ],
        ),
        content: const Text(
            'You have an active chat session. Would you like to clear it and start a new one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearActiveSession();
            },
            child: const Text('Clear Session'),
          ),
        ],
      ),
    );
  }

  void _handleRandomChatEvent(Map<String, dynamic> data) {
    print(
        '🎯 [CONNECT DEBUG] _handleRandomChatEvent called with mounted: $mounted');
    if (!mounted) {
      print('❌ [CONNECT DEBUG] Widget not mounted, aborting navigation');
      return;
    }

    print('🎯 [CONNECT DEBUG] Random chat event received with data: $data');

    // Extract session data directly from the event
    final event = data['event'];
    final sessionId = data['sessionId'];
    final chatRoomId = data['chatRoomId'];

    print('🎯 [CONNECT DEBUG] Event type: $event');
    print('🎯 [CONNECT DEBUG] Session ID: $sessionId');
    print('🎯 [CONNECT DEBUG] Chat Room ID: $chatRoomId');

    if (event == 'session_started' && sessionId != null && chatRoomId != null) {
      print('✅ [CONNECT DEBUG] Session started! About to navigate to chat...');
      print('   📱 Session ID: $sessionId');
      print('   💬 Chat Room ID: $chatRoomId');

      setState(() {
        _currentSessionId = sessionId;
        _isMatching = false;
        _isConnected = true;
        _matchMessage = 'Match found! Starting chat...';
      });

      print(
          '🔄 [CONNECT DEBUG] State updated, calling _navigateToRandomChat...');
      // Navigate to random chat screen
      _navigateToRandomChat(sessionId, chatRoomId);
    } else {
      print('⚠️ [CONNECT DEBUG] Unexpected event type or missing data');
      print('   🎭 Event: $event');
      print('   📱 Session ID: $sessionId');
      print('   💬 Chat Room ID: $chatRoomId');
      print('   📦 Full data: $data');

      // Handle other event types or show error
      setState(() {
        _isMatching = false;
        _matchMessage = 'Unexpected event: $event';
      });
    }
  }

  void _handleRandomChatTimeout() {
    if (!mounted) return;

    setState(() {
      _isMatching = false;
      _isConnected = false;
      _currentSessionId = null;
      _matchMessage = 'No match found. Please try again later.';
    });

    _showTimeoutDialog();
  }

  void _navigateToRandomChat(String sessionId, String chatRoomId) {
    print('🚀 [CONNECT DEBUG] _navigateToRandomChat called');
    print('   📱 Session ID: $sessionId');
    print('   💬 Chat Room ID: $chatRoomId');
    print('   🎯 Context available: ${context != null}');

    try {
      print('🔄 [CONNECT DEBUG] About to call Navigator.push...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            print('🏗️ [CONNECT DEBUG] Building RandomChatScreen...');
            return RandomChatScreen(
              sessionId: sessionId,
              chatRoomId: chatRoomId,
            );
          },
        ),
      ).then((_) {
        print(
            '🔙 [CONNECT DEBUG] Returned from RandomChatScreen, resetting state');
        // When returning from random chat, reset state
        setState(() {
          _isMatching = false;
          _isConnected = false;
          _currentSessionId = null;
          _matchMessage = null;
        });
      });
      print('✅ [CONNECT DEBUG] Navigator.push called successfully');
    } catch (e) {
      print('❌ [CONNECT DEBUG] Error during navigation: $e');
    }
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Match Found'),
          ],
        ),
        content: Text(_matchMessage ??
            'No match found after 5 minutes. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startMatching();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showWarningSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _startMatching() async {
    print('🎯 [CONNECT DEBUG] _startMatching called');
    print('   🔄 _isMatching: $_isMatching');
    print('   🔗 _isConnected: $_isConnected');
    print('   📱 _currentSessionId: $_currentSessionId');

    if (_isMatching || _isConnected) {
      print(
          '⚠️ [CONNECT DEBUG] Already matching or connected, ignoring duplicate call');
      return;
    }

    try {
      setState(() {
        _isMatching = true;
        _matchMessage = null;
        _queueTime = 0;
      });

      print('🔄 [CONNECT DEBUG] Starting random connection via socket');
      // Start random connection via socket
      await _socketService.startRandomConnection(
        country: _filters['region'],
        language: _filters['language'],
        interests: _filters['interests']?.cast<String>(),
      );

      print('✅ [CONNECT DEBUG] Random connection started successfully');
      // Start queue timer
      _startQueueTimer();

      // Show connecting message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Looking for a random chat partner...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ [CONNECT DEBUG] Failed to start matching: $e');
      setState(() {
        _isMatching = false;
        _matchMessage = 'Error: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start matching: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleImmediateMatch(Map<String, dynamic> connection) {
    setState(() {
      _isMatching = false;
      _isConnected = true;
      _matchMessage = 'Match found immediately!';
    });

    // Navigate to chat (you'll need to extract room ID from connection)
    // This depends on your connection data structure
  }

  void _startQueueTimer() {
    if (!_isMatching) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (_isMatching && mounted) {
        setState(() {
          _queueTime++;
        });
        _startQueueTimer();
      }
    });
  }

  Future<void> _stopMatching() async {
    if (!_isMatching && !_isConnected) return;

    try {
      setState(() {
        _isMatching = false;
        _isConnected = false;
        _queueTime = 0;
      });

      // Stop random connection via socket
      await _socketService.stopRandomConnection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterDialog(),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Premium Features'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upgrade to Premium to access:'),
            const SizedBox(height: 16),
            ...AppConstants.premiumFeatures.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'Premium features include advanced age filters and interest matching for better connections.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement premium upgrade
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.connect),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _showPremiumDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _buildMainContent(),
            ),
            _buildConnectButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isMatching) {
      return _buildMatchingScreen();
    }

    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find New People',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Connect with people within your preferred distance range',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildFilterSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    final theme = Theme.of(context);
    final selectedRange = AppConstants.distanceRanges.firstWhere(
      (range) => range['value'] == _filters['distance'],
      orElse: () => AppConstants.distanceRanges[0],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings,
                    size: 16, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text('Current Filters',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
                const Spacer(),
                if (!_isPremium)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilterItem('Distance', selectedRange['label']),
            _buildFilterItem('Language', _filters['language'] ?? 'Any'),

            // Premium features
            if (_isPremium) ...[
              _buildFilterItem('Age Range', _filters['ageRange'] ?? 'All'),
              if (_filters['interests']?.isNotEmpty == true)
                _buildFilterItem(
                    'Interests', '${_filters['interests'].length} selected'),
            ] else ...[
              _buildPremiumFilterItem('Age Range', 'Premium Only'),
              _buildPremiumFilterItem('Interests', 'Premium Only'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPremiumFilterItem(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: AppColors.warning),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingScreen() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 3,
                  ),
                ),
                Icon(
                  Icons.search,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding People...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for people within your selected distance range',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _stopMatching,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isMatching ? _stopMatching : _startMatching,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _isMatching ? Colors.red : theme.colorScheme.primary,
        ),
        child: Text(
          _isMatching ? 'Stop Matching' : 'Start Matching',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDistanceFilter(),
                  const SizedBox(height: 16),
                  _buildLanguageFilter(),

                  // Premium features
                  if (_isPremium) ...[
                    const SizedBox(height: 16),
                    _buildAgeRangeFilter(),
                    const SizedBox(height: 16),
                    _buildInterestsFilter(),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildPremiumFeatureCard(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _initializeFilters();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distance Range',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['distance'] ?? '1-5',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: AppConstants.distanceRanges.map((range) {
            return DropdownMenuItem<String>(
              value: range['value'] as String,
              child: Text(range['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filters['distance'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['language'] ?? 'any',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.language),
          ),
          items: const [
            DropdownMenuItem(value: 'any', child: Text('Any Language')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'es', child: Text('Spanish')),
            DropdownMenuItem(value: 'fr', child: Text('French')),
            DropdownMenuItem(value: 'de', child: Text('German')),
            DropdownMenuItem(value: 'it', child: Text('Italian')),
            DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
            DropdownMenuItem(value: 'ru', child: Text('Russian')),
            DropdownMenuItem(value: 'ja', child: Text('Japanese')),
            DropdownMenuItem(value: 'ko', child: Text('Korean')),
            DropdownMenuItem(value: 'zh', child: Text('Chinese')),
          ],
          onChanged: (value) {
            setState(() {
              _filters['language'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPremiumFeatureCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Premium Features',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Age Range & Interest Matching',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Get better matches with advanced age filters and interest-based connections.',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showPremiumDialog,
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Premium'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium-only filters (kept for premium users)
  Widget _buildAgeRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Age Range',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filters['ageRange'] ?? 'all',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.person),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Ages')),
            DropdownMenuItem(value: '18-25', child: Text('18-25')),
            DropdownMenuItem(value: '26-35', child: Text('26-35')),
            DropdownMenuItem(value: '36-45', child: Text('36-45')),
            DropdownMenuItem(value: '46+', child: Text('46+')),
          ],
          onChanged: (value) {
            setState(() {
              _filters['ageRange'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Interests',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.star, color: AppColors.warning, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            'Music',
            'Sports',
            'Travel',
            'Food',
            'Technology',
            'Art',
            'Books',
            'Movies',
            'Gaming',
            'Fitness',
            'Photography',
            'Cooking',
            'Dancing',
            'Writing',
            'Nature'
          ].map((interest) {
            final isSelected =
                (_filters['interests'] as List?)?.contains(interest) ?? false;
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (_filters['interests'] == null) {
                    _filters['interests'] = [];
                  }
                  if (selected) {
                    _filters['interests'].add(interest);
                  } else {
                    _filters['interests'].remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
