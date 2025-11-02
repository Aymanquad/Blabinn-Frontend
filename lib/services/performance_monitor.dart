import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/logger.dart';
import 'analytics_service.dart';

/// Performance monitoring service for production
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final AnalyticsService _analytics = AnalyticsService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  Timer? _monitoringTimer;
  final Map<String, PerformanceMetric> _metrics = {};
  final List<PerformanceEvent> _events = [];
  
  // Monitoring configuration
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const int _maxEvents = 1000;
  static const int _maxMetrics = 100;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing PerformanceMonitor...');

      // Start monitoring
      _startMonitoring();
      
      // Monitor app lifecycle
      _monitorAppLifecycle();
      
      // Monitor memory usage
      _monitorMemoryUsage();
      
      // Monitor network performance
      _monitorNetworkPerformance();

      _isInitialized = true;
      Logger.info('PerformanceMonitor initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize PerformanceMonitor', error: e);
      rethrow;
    }
  }

  /// Start periodic monitoring
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
    });
  }

  /// Monitor app lifecycle events
  void _monitorAppLifecycle() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// Monitor memory usage
  void _monitorMemoryUsage() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      _collectMemoryMetrics();
    });
  }

  /// Monitor network performance
  void _monitorNetworkPerformance() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _collectNetworkMetrics();
    });
  }

  /// Collect performance metrics
  Future<void> _collectMetrics() async {
    if (!_isEnabled) return;

    try {
      // Collect system metrics
      await _collectSystemMetrics();
      
      // Collect app metrics
      await _collectAppMetrics();
      
      // Collect device metrics
      await _collectDeviceMetrics();
      
      // Send metrics to analytics
      await _sendMetricsToAnalytics();
      
    } catch (e) {
      Logger.error('Failed to collect performance metrics', error: e);
    }
  }

  /// Collect system metrics
  Future<void> _collectSystemMetrics() async {
    try {
      // Memory usage
      final memoryInfo = await _getMemoryInfo();
      _addMetric('memory_usage', memoryInfo['used'] as double, 'MB');
      _addMetric('memory_available', memoryInfo['available'] as double, 'MB');
      _addMetric('memory_total', memoryInfo['total'] as double, 'MB');
      
      // CPU usage (approximate)
      final cpuUsage = await _getCpuUsage();
      _addMetric('cpu_usage', cpuUsage, '%');
      
      // Battery level
      final batteryLevel = await _getBatteryLevel();
      if (batteryLevel != null) {
        _addMetric('battery_level', batteryLevel, '%');
      }
      
    } catch (e) {
      Logger.error('Failed to collect system metrics', error: e);
    }
  }

  /// Collect app metrics
  Future<void> _collectAppMetrics() async {
    try {
      // App version
      final packageInfo = await PackageInfo.fromPlatform();
      _addMetric('app_version', packageInfo.version, 'version');
      
      // Build number
      _addMetric('build_number', int.tryParse(packageInfo.buildNumber) ?? 0, 'number');
      
      // App size (approximate)
      final appSize = await _getAppSize();
      if (appSize != null) {
        _addMetric('app_size', appSize, 'MB');
      }
      
    } catch (e) {
      Logger.error('Failed to collect app metrics', error: e);
    }
  }

  /// Collect device metrics
  Future<void> _collectDeviceMetrics() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _addMetric('android_version', androidInfo.version.release, 'version');
        _addMetric('device_model', androidInfo.model, 'model');
        _addMetric('device_brand', androidInfo.brand, 'brand');
        _addMetric('ram_total', androidInfo.totalMemory / (1024 * 1024 * 1024), 'GB');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _addMetric('ios_version', iosInfo.systemVersion, 'version');
        _addMetric('device_model', iosInfo.model, 'model');
        _addMetric('device_name', iosInfo.name, 'name');
      }
      
    } catch (e) {
      Logger.error('Failed to collect device metrics', error: e);
    }
  }

  /// Collect memory metrics
  Future<void> _collectMemoryMetrics() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      
      // Log memory usage event
      _addEvent(PerformanceEvent(
        type: 'memory_usage',
        value: memoryInfo['used'] as double,
        unit: 'MB',
        timestamp: DateTime.now(),
        metadata: {
          'available': memoryInfo['available'],
          'total': memoryInfo['total'],
          'usage_percentage': (memoryInfo['used'] as double) / (memoryInfo['total'] as double) * 100,
        },
      ));
      
    } catch (e) {
      Logger.error('Failed to collect memory metrics', error: e);
    }
  }

  /// Collect network metrics
  Future<void> _collectNetworkMetrics() async {
    try {
      // Network connectivity
      final connectivity = await _getNetworkConnectivity();
      _addMetric('network_connectivity', connectivity, 'status');
      
      // Network speed (approximate)
      final networkSpeed = await _getNetworkSpeed();
      if (networkSpeed != null) {
        _addMetric('network_speed', networkSpeed, 'Mbps');
      }
      
    } catch (e) {
      Logger.error('Failed to collect network metrics', error: e);
    }
  }

  /// Get memory information
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      // This is a simplified implementation
      // In a real app, you would use platform-specific methods
      return {
        'used': 100.0, // MB
        'available': 200.0, // MB
        'total': 300.0, // MB
      };
    } catch (e) {
      Logger.error('Failed to get memory info', error: e);
      return {'used': 0.0, 'available': 0.0, 'total': 0.0};
    }
  }

  /// Get CPU usage
  Future<double> _getCpuUsage() async {
    try {
      // This is a simplified implementation
      // In a real app, you would use platform-specific methods
      return 25.0; // Percentage
    } catch (e) {
      Logger.error('Failed to get CPU usage', error: e);
      return 0.0;
    }
  }

  /// Get battery level
  Future<double?> _getBatteryLevel() async {
    try {
      // This would require a battery plugin
      // For now, return null
      return null;
    } catch (e) {
      Logger.error('Failed to get battery level', error: e);
      return null;
    }
  }

  /// Get app size
  Future<double?> _getAppSize() async {
    try {
      // This is a simplified implementation
      // In a real app, you would use platform-specific methods
      return 50.0; // MB
    } catch (e) {
      Logger.error('Failed to get app size', error: e);
      return null;
    }
  }

  /// Get network connectivity
  Future<String> _getNetworkConnectivity() async {
    try {
      // This would require a connectivity plugin
      // For now, return a default value
      return 'wifi';
    } catch (e) {
      Logger.error('Failed to get network connectivity', error: e);
      return 'unknown';
    }
  }

  /// Get network speed
  Future<double?> _getNetworkSpeed() async {
    try {
      // This would require a network speed plugin
      // For now, return null
      return null;
    } catch (e) {
      Logger.error('Failed to get network speed', error: e);
      return null;
    }
  }

  /// Add performance metric
  void _addMetric(String name, dynamic value, String unit) {
    if (!_isEnabled) return;

    try {
      final metric = PerformanceMetric(
        name: name,
        value: value,
        unit: unit,
        timestamp: DateTime.now(),
      );
      
      _metrics[name] = metric;
      
      // Limit metrics count
      if (_metrics.length > _maxMetrics) {
        final oldestKey = _metrics.keys.first;
        _metrics.remove(oldestKey);
      }
      
    } catch (e) {
      Logger.error('Failed to add performance metric', error: e);
    }
  }

  /// Add performance event
  void _addEvent(PerformanceEvent event) {
    if (!_isEnabled) return;

    try {
      _events.add(event);
      
      // Limit events count
      if (_events.length > _maxEvents) {
        _events.removeAt(0);
      }
      
    } catch (e) {
      Logger.error('Failed to add performance event', error: e);
    }
  }

  /// Send metrics to analytics
  Future<void> _sendMetricsToAnalytics() async {
    try {
      for (final metric in _metrics.values) {
        await _analytics.logPerformance(
          metric.name,
          metric.value is double ? metric.value : 0.0,
          unit: metric.unit,
        );
      }
      
    } catch (e) {
      Logger.error('Failed to send metrics to analytics', error: e);
    }
  }

  /// Start performance tracking for a specific operation
  PerformanceTracker startTracking(String operation) {
    return PerformanceTracker(operation, this);
  }

  /// Record performance event
  void recordEvent(String type, double value, {String? unit, Map<String, dynamic>? metadata}) {
    _addEvent(PerformanceEvent(
      type: type,
      value: value,
      unit: unit ?? 'ms',
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    return PerformanceSummary(
      metrics: Map.from(_metrics),
      events: List.from(_events),
      totalEvents: _events.length,
      totalMetrics: _metrics.length,
    );
  }

  /// Enable/disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      _startMonitoring();
    } else {
      _monitoringTimer?.cancel();
    }
    
    Logger.info('Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _metrics.clear();
    _events.clear();
  }
}

/// Performance tracker for specific operations
class PerformanceTracker {
  final String operation;
  final PerformanceMonitor _monitor;
  final DateTime _startTime;
  final Stopwatch _stopwatch;

  PerformanceTracker(this.operation, this._monitor)
      : _startTime = DateTime.now(),
        _stopwatch = Stopwatch()..start();

  /// End tracking and record the performance
  void end({Map<String, dynamic>? metadata}) {
    _stopwatch.stop();
    final duration = _stopwatch.elapsedMilliseconds;
    
    _monitor.recordEvent(
      'operation_duration',
      duration.toDouble(),
      unit: 'ms',
      metadata: {
        'operation': operation,
        'start_time': _startTime.millisecondsSinceEpoch,
        'end_time': DateTime.now().millisecondsSinceEpoch,
        ...?metadata,
      },
    );
  }
}

/// Performance metric model
class PerformanceMetric {
  final String name;
  final dynamic value;
  final String unit;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}

/// Performance event model
class PerformanceEvent {
  final String type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceEvent({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
}

/// Performance summary model
class PerformanceSummary {
  final Map<String, PerformanceMetric> metrics;
  final List<PerformanceEvent> events;
  final int totalEvents;
  final int totalMetrics;

  PerformanceSummary({
    required this.metrics,
    required this.events,
    required this.totalEvents,
    required this.totalMetrics,
  });
}

/// App lifecycle observer for performance monitoring
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final PerformanceMonitor _monitor;

  _AppLifecycleObserver(this._monitor);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _monitor.recordEvent('app_resumed', 0, unit: 'event');
        break;
      case AppLifecycleState.paused:
        _monitor.recordEvent('app_paused', 0, unit: 'event');
        break;
      case AppLifecycleState.detached:
        _monitor.recordEvent('app_detached', 0, unit: 'event');
        break;
      case AppLifecycleState.inactive:
        _monitor.recordEvent('app_inactive', 0, unit: 'event');
        break;
      case AppLifecycleState.hidden:
        _monitor.recordEvent('app_hidden', 0, unit: 'event');
        break;
    }
  }
}
