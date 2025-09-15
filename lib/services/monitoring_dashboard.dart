import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'analytics_service.dart';
import 'performance_monitor.dart';
import 'crash_reporting_service.dart';

/// Monitoring dashboard service for production insights
class MonitoringDashboard {
  static final MonitoringDashboard _instance = MonitoringDashboard._internal();
  factory MonitoringDashboard() => _instance;
  MonitoringDashboard._internal();

  late AnalyticsService _analytics;
  late PerformanceMonitor _performanceMonitor;
  late CrashReportingService _crashReporting;
  late SharedPreferences _prefs;
  
  bool _isInitialized = false;
  Timer? _dashboardTimer;
  final Map<String, dynamic> _dashboardData = {};
  
  // Configuration
  static const Duration _updateInterval = Duration(minutes: 1);
  static const int _maxDataPoints = 1000;

  /// Initialize monitoring dashboard
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing MonitoringDashboard...');

      // Initialize services
      _analytics = AnalyticsService();
      _performanceMonitor = PerformanceMonitor();
      _crashReporting = CrashReportingService();
      _prefs = await SharedPreferences.getInstance();

      // Start dashboard updates
      _startDashboardUpdates();
      
      // Load historical data
      await _loadHistoricalData();

      _isInitialized = true;
      Logger.info('MonitoringDashboard initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize MonitoringDashboard', error: e);
      rethrow;
    }
  }

  /// Start periodic dashboard updates
  void _startDashboardUpdates() {
    _dashboardTimer?.cancel();
    _dashboardTimer = Timer.periodic(_updateInterval, (_) {
      _updateDashboardData();
    });
  }

  /// Update dashboard data
  Future<void> _updateDashboardData() async {
    try {
      // Collect analytics data
      final analyticsData = await _analytics.getAnalyticsData();
      
      // Collect performance data
      final performanceData = _performanceMonitor.getPerformanceSummary();
      
      // Collect crash data
      final crashSummary = _crashReporting.getCrashSummary();
      
      // Update dashboard data
      _dashboardData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      _dashboardData['analytics'] = _formatAnalyticsData(analyticsData);
      _dashboardData['performance'] = _formatPerformanceData(performanceData);
      _dashboardData['crashes'] = _formatCrashData(crashSummary);
      _dashboardData['app_health'] = _calculateAppHealth(analyticsData, performanceData, crashSummary);
      
      // Store data point
      await _storeDataPoint(_dashboardData);
      
      Logger.debug('Dashboard data updated');
    } catch (e) {
      Logger.error('Failed to update dashboard data', error: e);
    }
  }

  /// Format analytics data for dashboard
  Map<String, dynamic> _formatAnalyticsData(AnalyticsData analyticsData) {
    return {
      'session_id': analyticsData.sessionId,
      'user_id': analyticsData.userId,
      'total_events': analyticsData.totalEvents,
      'events_by_type': _groupEventsByType(analyticsData.events),
      'session_duration': _calculateSessionDuration(analyticsData.events),
      'user_engagement': _calculateUserEngagement(analyticsData.events),
    };
  }

  /// Format performance data for dashboard
  Map<String, dynamic> _formatPerformanceData(PerformanceSummary performanceData) {
    return {
      'total_metrics': performanceData.totalMetrics,
      'total_events': performanceData.totalEvents,
      'memory_usage': _getMemoryUsage(performanceData.metrics),
      'cpu_usage': _getCpuUsage(performanceData.metrics),
      'battery_level': _getBatteryLevel(performanceData.metrics),
      'network_status': _getNetworkStatus(performanceData.metrics),
      'app_performance': _calculateAppPerformance(performanceData),
    };
  }

  /// Format crash data for dashboard
  Map<String, dynamic> _formatCrashData(CrashSummary crashSummary) {
    return {
      'total_crashes': crashSummary.totalCrashes,
      'total_errors': crashSummary.totalErrors,
      'crashes_last_24h': crashSummary.crashesLast24Hours,
      'crashes_last_7d': crashSummary.crashesLast7Days,
      'errors_last_24h': crashSummary.errorsLast24Hours,
      'errors_last_7d': crashSummary.errorsLast7Days,
      'crash_rate': _calculateCrashRate(crashSummary),
      'error_rate': _calculateErrorRate(crashSummary),
    };
  }

  /// Calculate app health score
  double _calculateAppHealth(
    AnalyticsData analyticsData,
    PerformanceSummary performanceData,
    CrashSummary crashSummary,
  ) {
    try {
      double healthScore = 100.0;
      
      // Deduct points for crashes
      if (crashSummary.crashesLast24Hours > 0) {
        healthScore -= (crashSummary.crashesLast24Hours * 10);
      }
      
      // Deduct points for errors
      if (crashSummary.errorsLast24Hours > 10) {
        healthScore -= ((crashSummary.errorsLast24Hours - 10) * 2);
      }
      
      // Deduct points for poor performance
      final memoryUsage = _getMemoryUsage(performanceData.metrics);
      if (memoryUsage > 80) {
        healthScore -= 20;
      }
      
      // Deduct points for low engagement
      final engagement = _calculateUserEngagement(analyticsData.events);
      if (engagement < 0.3) {
        healthScore -= 15;
      }
      
      return healthScore.clamp(0.0, 100.0);
    } catch (e) {
      Logger.error('Failed to calculate app health', error: e);
      return 50.0; // Default health score
    }
  }

  /// Group events by type
  Map<String, int> _groupEventsByType(List<AnalyticsEvent> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      grouped[event.name] = (grouped[event.name] ?? 0) + 1;
    }
    return grouped;
  }

  /// Calculate session duration
  Duration _calculateSessionDuration(List<AnalyticsEvent> events) {
    if (events.isEmpty) return Duration.zero;
    
    final timestamps = events.map((e) => e.timestamp).toList();
    timestamps.sort();
    
    return timestamps.last.difference(timestamps.first);
  }

  /// Calculate user engagement
  double _calculateUserEngagement(List<AnalyticsEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final engagementEvents = events.where((e) => 
      e.name.contains('user_action') || 
      e.name.contains('feature_usage') ||
      e.name.contains('message_send')
    ).length;
    
    return engagementEvents / events.length;
  }

  /// Get memory usage from metrics
  double _getMemoryUsage(Map<String, PerformanceMetric> metrics) {
    final memoryMetric = metrics['memory_usage'];
    if (memoryMetric != null && memoryMetric.value is double) {
      return memoryMetric.value as double;
    }
    return 0.0;
  }

  /// Get CPU usage from metrics
  double _getCpuUsage(Map<String, PerformanceMetric> metrics) {
    final cpuMetric = metrics['cpu_usage'];
    if (cpuMetric != null && cpuMetric.value is double) {
      return cpuMetric.value as double;
    }
    return 0.0;
  }

  /// Get battery level from metrics
  double? _getBatteryLevel(Map<String, PerformanceMetric> metrics) {
    final batteryMetric = metrics['battery_level'];
    if (batteryMetric != null && batteryMetric.value is double) {
      return batteryMetric.value as double;
    }
    return null;
  }

  /// Get network status from metrics
  String _getNetworkStatus(Map<String, PerformanceMetric> metrics) {
    final networkMetric = metrics['network_connectivity'];
    if (networkMetric != null) {
      return networkMetric.value.toString();
    }
    return 'unknown';
  }

  /// Calculate app performance score
  double _calculateAppPerformance(PerformanceSummary performanceData) {
    try {
      double performanceScore = 100.0;
      
      // Check memory usage
      final memoryUsage = _getMemoryUsage(performanceData.metrics);
      if (memoryUsage > 100) {
        performanceScore -= 20;
      }
      
      // Check CPU usage
      final cpuUsage = _getCpuUsage(performanceData.metrics);
      if (cpuUsage > 50) {
        performanceScore -= 15;
      }
      
      // Check battery level
      final batteryLevel = _getBatteryLevel(performanceData.metrics);
      if (batteryLevel != null && batteryLevel < 20) {
        performanceScore -= 10;
      }
      
      return performanceScore.clamp(0.0, 100.0);
    } catch (e) {
      Logger.error('Failed to calculate app performance', error: e);
      return 50.0; // Default performance score
    }
  }

  /// Calculate crash rate
  double _calculateCrashRate(CrashSummary crashSummary) {
    if (crashSummary.crashesLast7Days == 0) return 0.0;
    
    // Assuming 1000 sessions per day on average
    const averageSessionsPerDay = 1000;
    const daysInWeek = 7;
    const totalSessions = averageSessionsPerDay * daysInWeek;
    
    return (crashSummary.crashesLast7Days / totalSessions) * 100;
  }

  /// Calculate error rate
  double _calculateErrorRate(CrashSummary crashSummary) {
    if (crashSummary.errorsLast7Days == 0) return 0.0;
    
    // Assuming 10000 user actions per day on average
    const averageActionsPerDay = 10000;
    const daysInWeek = 7;
    const totalActions = averageActionsPerDay * daysInWeek;
    
    return (crashSummary.errorsLast7Days / totalActions) * 100;
  }

  /// Store data point
  Future<void> _storeDataPoint(Map<String, dynamic> dataPoint) async {
    try {
      final dataPointsJson = _prefs.getString('dashboard_data_points');
      List<Map<String, dynamic>> dataPoints = [];
      
      if (dataPointsJson != null) {
        final pointsList = jsonDecode(dataPointsJson) as List;
        dataPoints = pointsList.cast<Map<String, dynamic>>();
      }
      
      dataPoints.add(dataPoint);
      
      // Limit data points
      if (dataPoints.length > _maxDataPoints) {
        dataPoints.removeAt(0);
      }
      
      await _prefs.setString('dashboard_data_points', jsonEncode(dataPoints));
    } catch (e) {
      Logger.error('Failed to store dashboard data point', error: e);
    }
  }

  /// Load historical data
  Future<void> _loadHistoricalData() async {
    try {
      final dataPointsJson = _prefs.getString('dashboard_data_points');
      if (dataPointsJson != null) {
        final pointsList = jsonDecode(dataPointsJson) as List;
        Logger.debug('Loaded ${pointsList.length} historical data points');
      }
    } catch (e) {
      Logger.error('Failed to load historical data', error: e);
    }
  }

  /// Get current dashboard data
  Map<String, dynamic> getCurrentData() {
    return Map.from(_dashboardData);
  }

  /// Get historical data
  Future<List<Map<String, dynamic>>> getHistoricalData() async {
    try {
      final dataPointsJson = _prefs.getString('dashboard_data_points');
      if (dataPointsJson != null) {
        final pointsList = jsonDecode(dataPointsJson) as List;
        return pointsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Logger.error('Failed to get historical data', error: e);
      return [];
    }
  }

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final currentData = getCurrentData();
      final historicalData = await getHistoricalData();
      
      return DashboardSummary(
        currentHealth: currentData['app_health'] ?? 0.0,
        averageHealth: _calculateAverageHealth(historicalData),
        totalSessions: historicalData.length,
        crashesLast24h: currentData['crashes']?['crashes_last_24h'] ?? 0,
        errorsLast24h: currentData['crashes']?['errors_last_24h'] ?? 0,
        memoryUsage: currentData['performance']?['memory_usage'] ?? 0.0,
        cpuUsage: currentData['performance']?['cpu_usage'] ?? 0.0,
        userEngagement: currentData['analytics']?['user_engagement'] ?? 0.0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Failed to get dashboard summary', error: e);
      return DashboardSummary();
    }
  }

  /// Calculate average health from historical data
  double _calculateAverageHealth(List<Map<String, dynamic>> historicalData) {
    if (historicalData.isEmpty) return 0.0;
    
    double totalHealth = 0.0;
    int validDataPoints = 0;
    
    for (final dataPoint in historicalData) {
      final health = dataPoint['app_health'];
      if (health is double) {
        totalHealth += health;
        validDataPoints++;
      }
    }
    
    return validDataPoints > 0 ? totalHealth / validDataPoints : 0.0;
  }

  /// Generate dashboard report
  Future<DashboardReport> generateReport() async {
    try {
      final summary = await getDashboardSummary();
      final historicalData = await getHistoricalData();
      
      return DashboardReport(
        summary: summary,
        historicalData: historicalData,
        generatedAt: DateTime.now(),
        reportId: _generateReportId(),
      );
    } catch (e) {
      Logger.error('Failed to generate dashboard report', error: e);
      return DashboardReport();
    }
  }

  /// Generate report ID
  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear historical data
  Future<void> clearHistoricalData() async {
    try {
      await _prefs.remove('dashboard_data_points');
      Logger.info('Historical dashboard data cleared');
    } catch (e) {
      Logger.error('Failed to clear historical data', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _dashboardTimer?.cancel();
    _dashboardData.clear();
  }
}

/// Dashboard summary model
class DashboardSummary {
  final double currentHealth;
  final double averageHealth;
  final int totalSessions;
  final int crashesLast24h;
  final int errorsLast24h;
  final double memoryUsage;
  final double cpuUsage;
  final double userEngagement;
  final DateTime lastUpdated;

  DashboardSummary({
    this.currentHealth = 0.0,
    this.averageHealth = 0.0,
    this.totalSessions = 0,
    this.crashesLast24h = 0,
    this.errorsLast24h = 0,
    this.memoryUsage = 0.0,
    this.cpuUsage = 0.0,
    this.userEngagement = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

/// Dashboard report model
class DashboardReport {
  final DashboardSummary summary;
  final List<Map<String, dynamic>> historicalData;
  final DateTime generatedAt;
  final String reportId;

  DashboardReport({
    required this.summary,
    required this.historicalData,
    required this.generatedAt,
    required this.reportId,
  });

  DashboardReport.empty()
      : summary = DashboardSummary(),
        historicalData = [],
        generatedAt = DateTime.now(),
        reportId = 'empty_report';
}
