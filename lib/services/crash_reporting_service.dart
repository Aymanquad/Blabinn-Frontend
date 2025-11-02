import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../utils/global_error_handler.dart';
import 'analytics_service.dart';

/// Comprehensive crash reporting service
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  late FirebaseCrashlytics _crashlytics;
  late SharedPreferences _prefs;
  late AnalyticsService _analytics;
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  final List<CrashReport> _crashReports = [];
  final List<ErrorReport> _errorReports = [];
  
  // Configuration
  static const int _maxReports = 100;
  static const Duration _reportRetention = Duration(days: 30);

  /// Initialize crash reporting service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing CrashReportingService...');

      // Initialize Firebase Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize Analytics Service
      _analytics = AnalyticsService();

      // Configure crashlytics
      await _configureCrashlytics();
      
      // Load existing reports
      await _loadReports();
      
      // Set up error handling
      _setupErrorHandling();

      _isInitialized = true;
      Logger.info('CrashReportingService initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize CrashReportingService', error: e);
      rethrow;
    }
  }

  /// Configure Firebase Crashlytics
  Future<void> _configureCrashlytics() async {
    try {
      // Enable crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(_isEnabled);
      
      // Set custom keys
      await _crashlytics.setCustomKey('app_version', '1.0.0');
      await _crashlytics.setCustomKey('platform', defaultTargetPlatform.name);
      await _crashlytics.setCustomKey('build_type', kDebugMode ? 'debug' : 'release');
      
      Logger.debug('Crashlytics configuration completed');
    } catch (e) {
      Logger.error('Failed to configure crashlytics', error: e);
    }
  }

  /// Load existing crash and error reports
  Future<void> _loadReports() async {
    try {
      // Load crash reports
      final crashReportsJson = _prefs.getString('crash_reports');
      if (crashReportsJson != null) {
        final reportsList = jsonDecode(crashReportsJson) as List;
        _crashReports.addAll(
          reportsList.map((r) => CrashReport.fromJson(r)).toList(),
        );
      }

      // Load error reports
      final errorReportsJson = _prefs.getString('error_reports');
      if (errorReportsJson != null) {
        final reportsList = jsonDecode(errorReportsJson) as List;
        _errorReports.addAll(
          reportsList.map((r) => ErrorReport.fromJson(r)).toList(),
        );
      }

      Logger.debug('Loaded ${_crashReports.length} crash reports and ${_errorReports.length} error reports');
    } catch (e) {
      Logger.error('Failed to load reports', error: e);
    }
  }

  /// Set up error handling
  void _setupErrorHandling() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Set up platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // Set up isolate error handling
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        _handleIsolateError(errorAndStacktrace[0], errorAndStacktrace[1]);
      }).sendPort,
    );
  }

  /// Handle Flutter errors
  Future<void> _handleFlutterError(FlutterErrorDetails details) async {
    try {
      Logger.error('Flutter error occurred', error: details.exception, stackTrace: details.stack);

      // Report to Firebase Crashlytics
      await _crashlytics.recordFlutterFatalError(details);

      // Create crash report
      final crashReport = CrashReport(
        id: _generateReportId(),
        type: CrashType.flutter,
        error: details.exception.toString(),
        stackTrace: details.stack?.toString(),
        context: details.context?.toString(),
        library: details.library,
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appState: await _getAppState(),
      );

      // Store report
      await _storeCrashReport(crashReport);

      // Send to analytics
      await _analytics.logError(
        'Flutter Error: ${details.exception}',
        stackTrace: details.stack,
        parameters: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );

    } catch (e) {
      Logger.error('Failed to handle Flutter error', error: e);
    }
  }

  /// Handle platform errors
  Future<void> _handlePlatformError(Object error, StackTrace stack) async {
    try {
      Logger.error('Platform error occurred', error: error, stackTrace: stack);

      // Report to Firebase Crashlytics
      await _crashlytics.recordError(error, stack);

      // Create crash report
      final crashReport = CrashReport(
        id: _generateReportId(),
        type: CrashType.platform,
        error: error.toString(),
        stackTrace: stack.toString(),
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appState: await _getAppState(),
      );

      // Store report
      await _storeCrashReport(crashReport);

      // Send to analytics
      await _analytics.logError(
        'Platform Error: $error',
        stackTrace: stack,
      );

    } catch (e) {
      Logger.error('Failed to handle platform error', error: e);
    }
  }

  /// Handle isolate errors
  Future<void> _handleIsolateError(Object error, StackTrace stack) async {
    try {
      Logger.error('Isolate error occurred', error: error, stackTrace: stack);

      // Report to Firebase Crashlytics
      await _crashlytics.recordError(error, stack);

      // Create crash report
      final crashReport = CrashReport(
        id: _generateReportId(),
        type: CrashType.isolate,
        error: error.toString(),
        stackTrace: stack.toString(),
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appState: await _getAppState(),
      );

      // Store report
      await _storeCrashReport(crashReport);

      // Send to analytics
      await _analytics.logError(
        'Isolate Error: $error',
        stackTrace: stack,
      );

    } catch (e) {
      Logger.error('Failed to handle isolate error', error: e);
    }
  }

  /// Record a custom error
  Future<void> recordError(
    String error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Logger.error('Custom error recorded: $error', error: error, stackTrace: stackTrace);

      // Report to Firebase Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        information: metadata?.entries
            .map((e) => DiagnosticsProperty(e.key, e.value))
            .toList(),
      );

      // Create error report
      final errorReport = ErrorReport(
        id: _generateReportId(),
        error: error,
        stackTrace: stackTrace?.toString(),
        context: context,
        metadata: metadata,
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appState: await _getAppState(),
      );

      // Store report
      await _storeErrorReport(errorReport);

      // Send to analytics
      await _analytics.logError(
        'Custom Error: $error',
        stackTrace: stackTrace,
        parameters: {
          'context': context,
          ...?metadata,
        },
      );

    } catch (e) {
      Logger.error('Failed to record custom error', error: e);
    }
  }

  /// Record a non-fatal error
  Future<void> recordNonFatalError(
    String error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Logger.warning('Non-fatal error recorded: $error');

      // Report to Firebase Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: false,
        information: metadata?.entries
            .map((e) => DiagnosticsProperty(e.key, e.value))
            .toList(),
      );

      // Create error report
      final errorReport = ErrorReport(
        id: _generateReportId(),
        error: error,
        stackTrace: stackTrace?.toString(),
        context: context,
        metadata: metadata,
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appState: await _getAppState(),
        isFatal: false,
      );

      // Store report
      await _storeErrorReport(errorReport);

      // Send to analytics
      await _analytics.logError(
        'Non-Fatal Error: $error',
        stackTrace: stackTrace,
        parameters: {
          'context': context,
          'is_fatal': false,
          ...?metadata,
        },
      );

    } catch (e) {
      Logger.error('Failed to record non-fatal error', error: e);
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      Logger.debug('Crashlytics user ID set: $userId');
    } catch (e) {
      Logger.error('Failed to set crashlytics user ID', error: e);
    }
  }

  /// Set custom key for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
      Logger.debug('Crashlytics custom key set: $key = $value');
    } catch (e) {
      Logger.error('Failed to set crashlytics custom key', error: e);
    }
  }

  /// Log a breadcrumb for crash context
  Future<void> logBreadcrumb(String message, {Map<String, dynamic>? data}) async {
    try {
      await _crashlytics.log(message);
      Logger.debug('Crashlytics breadcrumb logged: $message');
    } catch (e) {
      Logger.error('Failed to log crashlytics breadcrumb', error: e);
    }
  }

  /// Store crash report
  Future<void> _storeCrashReport(CrashReport report) async {
    try {
      _crashReports.add(report);
      
      // Limit reports count
      if (_crashReports.length > _maxReports) {
        _crashReports.removeAt(0);
      }
      
      // Save to storage
      final reportsJson = _crashReports.map((r) => r.toJson()).toList();
      await _prefs.setString('crash_reports', jsonEncode(reportsJson));
      
      Logger.debug('Crash report stored: ${report.id}');
    } catch (e) {
      Logger.error('Failed to store crash report', error: e);
    }
  }

  /// Store error report
  Future<void> _storeErrorReport(ErrorReport report) async {
    try {
      _errorReports.add(report);
      
      // Limit reports count
      if (_errorReports.length > _maxReports) {
        _errorReports.removeAt(0);
      }
      
      // Save to storage
      final reportsJson = _errorReports.map((r) => r.toJson()).toList();
      await _prefs.setString('error_reports', jsonEncode(reportsJson));
      
      Logger.debug('Error report stored: ${report.id}');
    } catch (e) {
      Logger.error('Failed to store error report', error: e);
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'platform': defaultTargetPlatform.name,
        'is_debug': kDebugMode,
        'is_release': kReleaseMode,
        'is_profile': kProfileMode,
      };
    } catch (e) {
      Logger.error('Failed to get device info', error: e);
      return {};
    }
  }

  /// Get app state information
  Future<Map<String, dynamic>> _getAppState() async {
    try {
      return {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'memory_usage': 'unknown', // Would need platform-specific implementation
        'network_status': 'unknown', // Would need connectivity plugin
      };
    } catch (e) {
      Logger.error('Failed to get app state', error: e);
      return {};
    }
  }

  /// Generate unique report ID
  String _generateReportId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Get crash reports
  List<CrashReport> getCrashReports() {
    return List.from(_crashReports);
  }

  /// Get error reports
  List<ErrorReport> getErrorReports() {
    return List.from(_errorReports);
  }

  /// Get crash summary
  CrashSummary getCrashSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final crashesLast24Hours = _crashReports.where(
      (r) => r.timestamp.isAfter(last24Hours),
    ).length;
    
    final crashesLast7Days = _crashReports.where(
      (r) => r.timestamp.isAfter(last7Days),
    ).length;
    
    final errorsLast24Hours = _errorReports.where(
      (r) => r.timestamp.isAfter(last24Hours),
    ).length;
    
    final errorsLast7Days = _errorReports.where(
      (r) => r.timestamp.isAfter(last7Days),
    ).length;
    
    return CrashSummary(
      totalCrashes: _crashReports.length,
      totalErrors: _errorReports.length,
      crashesLast24Hours: crashesLast24Hours,
      crashesLast7Days: crashesLast7Days,
      errorsLast24Hours: errorsLast24Hours,
      errorsLast7Days: errorsLast7Days,
    );
  }

  /// Clear old reports
  Future<void> clearOldReports() async {
    try {
      final cutoffDate = DateTime.now().subtract(_reportRetention);
      
      _crashReports.removeWhere((r) => r.timestamp.isBefore(cutoffDate));
      _errorReports.removeWhere((r) => r.timestamp.isBefore(cutoffDate));
      
      // Save updated reports
      final crashReportsJson = _crashReports.map((r) => r.toJson()).toList();
      await _prefs.setString('crash_reports', jsonEncode(crashReportsJson));
      
      final errorReportsJson = _errorReports.map((r) => r.toJson()).toList();
      await _prefs.setString('error_reports', jsonEncode(errorReportsJson));
      
      Logger.info('Old crash and error reports cleared');
    } catch (e) {
      Logger.error('Failed to clear old reports', error: e);
    }
  }

  /// Enable/disable crash reporting
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    
    Logger.info('Crash reporting ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Dispose resources
  void dispose() {
    _crashReports.clear();
    _errorReports.clear();
  }
}

/// Crash report model
class CrashReport {
  final String id;
  final CrashType type;
  final String error;
  final String? stackTrace;
  final String? context;
  final String? library;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appState;

  CrashReport({
    required this.id,
    required this.type,
    required this.error,
    this.stackTrace,
    this.context,
    this.library,
    required this.timestamp,
    required this.deviceInfo,
    required this.appState,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'error': error,
      'stackTrace': stackTrace,
      'context': context,
      'library': library,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceInfo': deviceInfo,
      'appState': appState,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'],
      type: CrashType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CrashType.unknown,
      ),
      error: json['error'],
      stackTrace: json['stackTrace'],
      context: json['context'],
      library: json['library'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo']),
      appState: Map<String, dynamic>.from(json['appState']),
    );
  }
}

/// Error report model
class ErrorReport {
  final String id;
  final String error;
  final String? stackTrace;
  final String? context;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appState;
  final bool isFatal;

  ErrorReport({
    required this.id,
    required this.error,
    this.stackTrace,
    this.context,
    this.metadata,
    required this.timestamp,
    required this.deviceInfo,
    required this.appState,
    this.isFatal = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'error': error,
      'stackTrace': stackTrace,
      'context': context,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceInfo': deviceInfo,
      'appState': appState,
      'isFatal': isFatal,
    };
  }

  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      id: json['id'],
      error: json['error'],
      stackTrace: json['stackTrace'],
      context: json['context'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo']),
      appState: Map<String, dynamic>.from(json['appState']),
      isFatal: json['isFatal'] ?? true,
    );
  }
}

/// Crash type enum
enum CrashType {
  flutter,
  platform,
  isolate,
  unknown,
}

/// Crash summary model
class CrashSummary {
  final int totalCrashes;
  final int totalErrors;
  final int crashesLast24Hours;
  final int crashesLast7Days;
  final int errorsLast24Hours;
  final int errorsLast7Days;

  CrashSummary({
    required this.totalCrashes,
    required this.totalErrors,
    required this.crashesLast24Hours,
    required this.crashesLast7Days,
    required this.errorsLast24Hours,
    required this.errorsLast7Days,
  });
}
