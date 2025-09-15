import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../core/config.dart';

/// Comprehensive analytics service for production monitoring
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _firebaseAnalytics;
  late FirebaseCrashlytics _crashlytics;
  late SharedPreferences _prefs;
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  String? _userId;
  String? _sessionId;
  final Map<String, dynamic> _sessionData = {};
  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;

  // Analytics configuration
  static const int _maxQueueSize = 100;
  static const Duration _flushInterval = Duration(minutes: 5);
  static const Duration _sessionTimeout = Duration(minutes: 30);

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing AnalyticsService...');

      // Initialize Firebase Analytics
      _firebaseAnalytics = FirebaseAnalytics.instance;
      
      // Initialize Firebase Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Configure analytics settings
      await _configureAnalytics();
      
      // Load session data
      await _loadSessionData();
      
      // Start session
      await _startSession();
      
      // Start periodic flush
      _startFlushTimer();

      _isInitialized = true;
      Logger.info('AnalyticsService initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize AnalyticsService', error: e);
      rethrow;
    }
  }

  /// Configure analytics settings
  Future<void> _configureAnalytics() async {
    try {
      // Set analytics collection enabled
      await _firebaseAnalytics.setAnalyticsCollectionEnabled(_isEnabled);
      
      // Set crashlytics collection enabled
      await _crashlytics.setCrashlyticsCollectionEnabled(_isEnabled);
      
      // Set user consent
      await _firebaseAnalytics.setConsent(
        adStorageConsent: ConsentStatus.granted,
        analyticsStorageConsent: ConsentStatus.granted,
      );

      Logger.debug('Analytics configuration completed');
    } catch (e) {
      Logger.error('Failed to configure analytics', error: e);
    }
  }

  /// Load session data from storage
  Future<void> _loadSessionData() async {
    try {
      _sessionId = _prefs.getString('analytics_session_id');
      _userId = _prefs.getString('analytics_user_id');
      
      final sessionDataJson = _prefs.getString('analytics_session_data');
      if (sessionDataJson != null) {
        final sessionData = jsonDecode(sessionDataJson) as Map<String, dynamic>;
        _sessionData.addAll(sessionData);
      }

      Logger.debug('Session data loaded: sessionId=$_sessionId, userId=$_userId');
    } catch (e) {
      Logger.error('Failed to load session data', error: e);
    }
  }

  /// Start a new analytics session
  Future<void> _startSession() async {
    try {
      // Generate new session ID if needed
      if (_sessionId == null) {
        _sessionId = _generateSessionId();
        await _prefs.setString('analytics_session_id', _sessionId!);
      }

      // Set session parameters
      await _firebaseAnalytics.setSessionTimeoutDuration(_sessionTimeout);
      
      // Log session start
      await logEvent('session_start', parameters: {
        'session_id': _sessionId!,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'app_version': AppConfig.appVersion,
        'platform': defaultTargetPlatform.name,
      });

      Logger.debug('Analytics session started: $_sessionId');
    } catch (e) {
      Logger.error('Failed to start analytics session', error: e);
    }
  }

  /// Start periodic flush timer
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      _flushEvents();
    });
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    try {
      _userId = userId;
      await _prefs.setString('analytics_user_id', userId);
      await _firebaseAnalytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
      
      Logger.debug('Analytics user ID set: $userId');
    } catch (e) {
      Logger.error('Failed to set analytics user ID', error: e);
    }
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      for (final entry in properties.entries) {
        await _firebaseAnalytics.setUserProperty(
          name: entry.key,
          value: entry.value?.toString(),
        );
      }
      
      Logger.debug('User properties set: $properties');
    } catch (e) {
      Logger.error('Failed to set user properties', error: e);
    }
  }

  /// Log custom event
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      // Add common parameters
      final eventParams = <String, dynamic>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_id': _sessionId,
        'user_id': _userId,
        'app_version': AppConfig.appVersion,
        'platform': defaultTargetPlatform.name,
        ...?parameters,
      };

      // Create analytics event
      final event = AnalyticsEvent(
        name: eventName,
        parameters: eventParams,
        timestamp: DateTime.now(),
      );

      // Add to queue
      _eventQueue.add(event);

      // Log to Firebase Analytics
      await _firebaseAnalytics.logEvent(
        name: eventName,
        parameters: eventParams,
      );

      // Flush if queue is full
      if (_eventQueue.length >= _maxQueueSize) {
        await _flushEvents();
      }

      Logger.debug('Analytics event logged: $eventName');
    } catch (e) {
      Logger.error('Failed to log analytics event: $eventName', error: e);
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await logEvent('screen_view', parameters: {
      'screen_name': screenName,
      'screen_class': screenClass ?? screenName,
    });
  }

  /// Log user action
  Future<void> logUserAction(String action, {Map<String, dynamic>? parameters}) async {
    await logEvent('user_action', parameters: {
      'action': action,
      ...?parameters,
    });
  }

  /// Log app performance metrics
  Future<void> logPerformance(String metric, double value, {String? unit}) async {
    await logEvent('performance_metric', parameters: {
      'metric': metric,
      'value': value,
      'unit': unit ?? 'ms',
    });
  }

  /// Log error
  Future<void> logError(String error, {StackTrace? stackTrace, Map<String, dynamic>? parameters}) async {
    try {
      // Log to Firebase Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        information: parameters?.entries
            .map((e) => DiagnosticsProperty(e.key, e.value))
            .toList(),
      );

      // Log as analytics event
      await logEvent('error_occurred', parameters: {
        'error': error,
        'stack_trace': stackTrace?.toString(),
        ...?parameters,
      });

      Logger.error('Analytics error logged: $error');
    } catch (e) {
      Logger.error('Failed to log analytics error', error: e);
    }
  }

  /// Log business metrics
  Future<void> logBusinessMetric(String metric, double value, {String? currency}) async {
    await logEvent('business_metric', parameters: {
      'metric': metric,
      'value': value,
      'currency': currency ?? 'USD',
    });
  }

  /// Log feature usage
  Future<void> logFeatureUsage(String feature, {Map<String, dynamic>? parameters}) async {
    await logEvent('feature_usage', parameters: {
      'feature': feature,
      ...?parameters,
    });
  }

  /// Log conversion event
  Future<void> logConversion(String conversion, {double? value, String? currency}) async {
    await logEvent('conversion', parameters: {
      'conversion': conversion,
      'value': value,
      'currency': currency ?? 'USD',
    });
  }

  /// Flush queued events
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      // Save events to local storage for offline analysis
      final eventsJson = _eventQueue.map((e) => e.toJson()).toList();
      await _prefs.setString('analytics_events_queue', jsonEncode(eventsJson));

      // Clear queue
      _eventQueue.clear();

      Logger.debug('Analytics events flushed: ${eventsJson.length} events');
    } catch (e) {
      Logger.error('Failed to flush analytics events', error: e);
    }
  }

  /// Get analytics data
  Future<AnalyticsData> getAnalyticsData() async {
    try {
      final eventsJson = _prefs.getString('analytics_events_queue');
      List<AnalyticsEvent> events = [];
      
      if (eventsJson != null) {
        final eventsList = jsonDecode(eventsJson) as List;
        events = eventsList.map((e) => AnalyticsEvent.fromJson(e)).toList();
      }

      return AnalyticsData(
        sessionId: _sessionId,
        userId: _userId,
        totalEvents: events.length,
        events: events,
        sessionData: Map.from(_sessionData),
      );
    } catch (e) {
      Logger.error('Failed to get analytics data', error: e);
      return AnalyticsData();
    }
  }

  /// Enable/disable analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _firebaseAnalytics.setAnalyticsCollectionEnabled(enabled);
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    
    Logger.info('Analytics ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      await _prefs.remove('analytics_session_id');
      await _prefs.remove('analytics_user_id');
      await _prefs.remove('analytics_session_data');
      await _prefs.remove('analytics_events_queue');
      
      _sessionId = null;
      _userId = null;
      _sessionData.clear();
      _eventQueue.clear();
      
      Logger.info('Analytics data cleared');
    } catch (e) {
      Logger.error('Failed to clear analytics data', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _flushTimer?.cancel();
    _flushEvents();
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

/// Analytics data model
class AnalyticsData {
  final String? sessionId;
  final String? userId;
  final int totalEvents;
  final List<AnalyticsEvent> events;
  final Map<String, dynamic> sessionData;

  AnalyticsData({
    this.sessionId,
    this.userId,
    this.totalEvents = 0,
    this.events = const [],
    this.sessionData = const {},
  });
}

/// Analytics event constants
class AnalyticsEvents {
  // App lifecycle
  static const String appStart = 'app_start';
  static const String appResume = 'app_resume';
  static const String appPause = 'app_pause';
  static const String appStop = 'app_stop';
  
  // Authentication
  static const String login = 'login';
  static const String logout = 'logout';
  static const String signUp = 'sign_up';
  static const String guestLogin = 'guest_login';
  
  // User actions
  static const String profileView = 'profile_view';
  static const String profileEdit = 'profile_edit';
  static const String imageUpload = 'image_upload';
  static const String search = 'search';
  
  // Chat
  static const String chatStart = 'chat_start';
  static const String chatEnd = 'chat_end';
  static const String messageSend = 'message_send';
  static const String messageReceive = 'message_receive';
  
  // Matching
  static const String matchStart = 'match_start';
  static const String matchFound = 'match_found';
  static const String matchAccept = 'match_accept';
  static const String matchReject = 'match_reject';
  
  // Monetization
  static const String creditEarn = 'credit_earn';
  static const String creditSpend = 'credit_spend';
  static const String purchaseStart = 'purchase_start';
  static const String purchaseComplete = 'purchase_complete';
  
  // Ads
  static const String adLoad = 'ad_load';
  static const String adShow = 'ad_show';
  static const String adClick = 'ad_click';
  static const String adReward = 'ad_reward';
  
  // Errors
  static const String error = 'error';
  static const String crash = 'crash';
  static const String networkError = 'network_error';
  
  // Performance
  static const String performance = 'performance';
  static const String memoryUsage = 'memory_usage';
  static const String batteryUsage = 'battery_usage';
}

/// Analytics parameters constants
class AnalyticsParameters {
  // Common
  static const String userId = 'user_id';
  static const String sessionId = 'session_id';
  static const String timestamp = 'timestamp';
  static const String appVersion = 'app_version';
  static const String platform = 'platform';
  
  // User
  static const String userType = 'user_type';
  static const String isPremium = 'is_premium';
  static const String credits = 'credits';
  
  // Chat
  static const String chatId = 'chat_id';
  static const String messageType = 'message_type';
  static const String messageLength = 'message_length';
  
  // Matching
  static const String matchId = 'match_id';
  static const String queueTime = 'queue_time';
  static const String filters = 'filters';
  
  // Monetization
  static const String amount = 'amount';
  static const String currency = 'currency';
  static const String productId = 'product_id';
  static const String purchaseType = 'purchase_type';
  
  // Performance
  static const String metric = 'metric';
  static const String value = 'value';
  static const String unit = 'unit';
  
  // Error
  static const String error = 'error';
  static const String stackTrace = 'stack_trace';
  static const String errorType = 'error_type';
}
