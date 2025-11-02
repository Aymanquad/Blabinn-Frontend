# Analytics and Monitoring Guide

This guide covers the comprehensive analytics and monitoring system implemented in the Chatify application for production insights and performance tracking.

## Overview

The analytics and monitoring system consists of several integrated services:

1. **AnalyticsService** - Event tracking and user behavior analysis
2. **PerformanceMonitor** - App performance metrics and monitoring
3. **CrashReportingService** - Error tracking and crash reporting
4. **MonitoringDashboard** - Real-time monitoring dashboard

## Analytics Service

### Features

- **Event Tracking**: Custom events with parameters
- **User Analytics**: User behavior and engagement tracking
- **Session Management**: Session tracking and analysis
- **Firebase Integration**: Firebase Analytics and Crashlytics
- **Offline Support**: Event queuing for offline scenarios
- **Privacy Compliance**: User consent and data protection

### Usage Examples

#### Basic Event Tracking

```dart
final analytics = AnalyticsService();
await analytics.initialize();

// Log custom event
await analytics.logEvent('button_click', parameters: {
  'button_name': 'login',
  'screen': 'login_screen',
});

// Log screen view
await analytics.logScreenView('home_screen');

// Log user action
await analytics.logUserAction('profile_edit', parameters: {
  'field': 'bio',
  'length': 150,
});
```

#### User Analytics

```dart
// Set user ID
await analytics.setUserId('user_123');

// Set user properties
await analytics.setUserProperties({
  'user_type': 'premium',
  'signup_date': '2023-01-01',
  'country': 'US',
});

// Log conversion
await analytics.logConversion('premium_upgrade', value: 9.99, currency: 'USD');
```

#### Business Metrics

```dart
// Log business metrics
await analytics.logBusinessMetric('revenue', 99.99, currency: 'USD');
await analytics.logBusinessMetric('user_acquisition_cost', 5.50, currency: 'USD');

// Log feature usage
await analytics.logFeatureUsage('premium_matching', parameters: {
  'filters_applied': 3,
  'matches_found': 5,
});
```

### Event Constants

The service includes predefined event constants:

```dart
// App lifecycle
AnalyticsEvents.appStart
AnalyticsEvents.appResume
AnalyticsEvents.appPause

// Authentication
AnalyticsEvents.login
AnalyticsEvents.logout
AnalyticsEvents.signUp

// User actions
AnalyticsEvents.profileView
AnalyticsEvents.profileEdit
AnalyticsEvents.search

// Chat
AnalyticsEvents.chatStart
AnalyticsEvents.messageSend
AnalyticsEvents.messageReceive

// Matching
AnalyticsEvents.matchStart
AnalyticsEvents.matchFound
AnalyticsEvents.matchAccept

// Monetization
AnalyticsEvents.creditEarn
AnalyticsEvents.creditSpend
AnalyticsEvents.purchaseComplete

// Ads
AnalyticsEvents.adLoad
AnalyticsEvents.adShow
AnalyticsEvents.adReward
```

## Performance Monitor

### Features

- **System Metrics**: Memory, CPU, battery monitoring
- **App Metrics**: Performance tracking and optimization
- **Device Metrics**: Device-specific performance data
- **Real-time Monitoring**: Continuous performance tracking
- **Performance Events**: Detailed performance event logging
- **Analytics Integration**: Performance data in analytics

### Usage Examples

#### Basic Performance Tracking

```dart
final monitor = PerformanceMonitor();
await monitor.initialize();

// Start tracking an operation
final tracker = monitor.startTracking('api_call');
// ... perform operation
tracker.end(metadata: {'endpoint': '/users', 'response_time': 150});

// Record performance event
monitor.recordEvent('image_load', 250.0, unit: 'ms', metadata: {
  'image_size': '2MB',
  'cache_hit': false,
});
```

#### Performance Metrics

```dart
// Get performance summary
final summary = monitor.getPerformanceSummary();
print('Total metrics: ${summary.totalMetrics}');
print('Total events: ${summary.totalEvents}');

// Access specific metrics
final memoryUsage = summary.metrics['memory_usage'];
if (memoryUsage != null) {
  print('Memory usage: ${memoryUsage.value} ${memoryUsage.unit}');
}
```

### Monitored Metrics

- **Memory Usage**: RAM consumption and availability
- **CPU Usage**: Processor utilization
- **Battery Level**: Device battery status
- **Network Status**: Connectivity and speed
- **App Size**: Application storage usage
- **Performance Events**: Custom performance tracking

## Crash Reporting Service

### Features

- **Automatic Crash Detection**: Flutter, platform, and isolate errors
- **Custom Error Reporting**: Manual error logging
- **Firebase Integration**: Firebase Crashlytics integration
- **Error Context**: Rich error context and metadata
- **Offline Support**: Error queuing for offline scenarios
- **Error Analytics**: Error trends and patterns

### Usage Examples

#### Automatic Crash Reporting

```dart
final crashReporting = CrashReportingService();
await crashReporting.initialize();

// Errors are automatically captured and reported
// No additional code needed for automatic reporting
```

#### Custom Error Reporting

```dart
// Record custom error
await crashReporting.recordError(
  'API request failed',
  stackTrace: stackTrace,
  context: 'User profile loading',
  metadata: {
    'endpoint': '/api/profile',
    'user_id': 'user_123',
    'retry_count': 3,
  },
);

// Record non-fatal error
await crashReporting.recordNonFatalError(
  'Image loading failed',
  context: 'Profile image display',
  metadata: {
    'image_url': 'https://example.com/image.jpg',
    'fallback_used': true,
  },
);
```

#### User Context

```dart
// Set user identifier
await crashReporting.setUserId('user_123');

// Set custom keys
await crashReporting.setCustomKey('user_type', 'premium');
await crashReporting.setCustomKey('app_version', '1.0.0');

// Log breadcrumbs
await crashReporting.logBreadcrumb('User started chat', data: {
  'chat_id': 'chat_123',
  'participant_count': 2,
});
```

### Error Types

- **Flutter Errors**: UI and widget errors
- **Platform Errors**: Native platform errors
- **Isolate Errors**: Background thread errors
- **Custom Errors**: Application-specific errors
- **Non-fatal Errors**: Recoverable errors

## Monitoring Dashboard

### Features

- **Real-time Monitoring**: Live app health and performance
- **Historical Data**: Trend analysis and historical insights
- **Health Scoring**: Overall app health calculation
- **Performance Metrics**: Comprehensive performance tracking
- **Crash Analytics**: Error and crash trend analysis
- **User Engagement**: User behavior and engagement metrics

### Usage Examples

#### Dashboard Access

```dart
final dashboard = MonitoringDashboard();
await dashboard.initialize();

// Get current dashboard data
final currentData = dashboard.getCurrentData();
print('App health: ${currentData['app_health']}');

// Get dashboard summary
final summary = await dashboard.getDashboardSummary();
print('Current health: ${summary.currentHealth}');
print('Average health: ${summary.averageHealth}');
print('Crashes last 24h: ${summary.crashesLast24h}');
```

#### Historical Analysis

```dart
// Get historical data
final historicalData = await dashboard.getHistoricalData();
print('Total data points: ${historicalData.length}');

// Generate comprehensive report
final report = await dashboard.generateReport();
print('Report ID: ${report.reportId}');
print('Generated at: ${report.generatedAt}');
```

### Dashboard Metrics

- **App Health Score**: Overall application health (0-100)
- **Performance Metrics**: Memory, CPU, battery usage
- **Crash Analytics**: Crash and error rates
- **User Engagement**: User activity and engagement
- **Session Analytics**: Session duration and frequency
- **Feature Usage**: Feature adoption and usage patterns

## Integration Examples

### Complete Setup

```dart
class AppMonitoring {
  static Future<void> initialize() async {
    // Initialize all monitoring services
    await AnalyticsService().initialize();
    await PerformanceMonitor().initialize();
    await CrashReportingService().initialize();
    await MonitoringDashboard().initialize();
    
    // Set up user context
    final userId = await getCurrentUserId();
    if (userId != null) {
      await AnalyticsService().setUserId(userId);
      await CrashReportingService().setUserId(userId);
    }
  }
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize monitoring
  await AppMonitoring.initialize();
  
  runApp(MyApp());
}
```

### Widget Integration

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _analytics = AnalyticsService();
  final _performanceMonitor = PerformanceMonitor();
  
  @override
  void initState() {
    super.initState();
    
    // Track screen view
    _analytics.logScreenView('my_widget');
    
    // Start performance tracking
    _tracker = _performanceMonitor.startTracking('widget_build');
  }
  
  @override
  void dispose() {
    _tracker?.end();
    super.dispose();
  }
  
  void _handleButtonClick() {
    // Track user action
    _analytics.logUserAction('button_click', parameters: {
      'button': 'submit',
      'screen': 'my_widget',
    });
  }
}
```

### Service Integration

```dart
class ApiService {
  final _analytics = AnalyticsService();
  final _crashReporting = CrashReportingService();
  final _performanceMonitor = PerformanceMonitor();
  
  Future<Map<String, dynamic>> makeRequest(String endpoint) async {
    final tracker = _performanceMonitor.startTracking('api_request');
    
    try {
      // Track API call
      await _analytics.logEvent('api_request', parameters: {
        'endpoint': endpoint,
        'method': 'GET',
      });
      
      final response = await http.get(Uri.parse(endpoint));
      
      // Track success
      await _analytics.logEvent('api_success', parameters: {
        'endpoint': endpoint,
        'status_code': response.statusCode,
      });
      
      tracker.end(metadata: {
        'endpoint': endpoint,
        'status_code': response.statusCode,
      });
      
      return jsonDecode(response.body);
    } catch (e, stackTrace) {
      // Track error
      await _crashReporting.recordError(
        'API request failed: $endpoint',
        stackTrace: stackTrace,
        context: 'API Service',
        metadata: {
          'endpoint': endpoint,
          'method': 'GET',
        },
      );
      
      tracker.end(metadata: {
        'endpoint': endpoint,
        'error': e.toString(),
      });
      
      rethrow;
    }
  }
}
```

## Best Practices

### 1. Event Naming

Use consistent, descriptive event names:

```dart
// Good
'user_profile_edit'
'chat_message_send'
'premium_feature_use'

// Avoid
'click'
'action'
'event'
```

### 2. Parameter Usage

Include relevant context in event parameters:

```dart
await analytics.logEvent('feature_usage', parameters: {
  'feature_name': 'premium_matching',
  'user_type': 'premium',
  'session_duration': 300,
  'success': true,
});
```

### 3. Performance Tracking

Track performance for critical operations:

```dart
final tracker = monitor.startTracking('image_processing');
try {
  await processImage(imageFile);
  tracker.end(metadata: {'image_size': imageFile.lengthSync()});
} catch (e) {
  tracker.end(metadata: {'error': e.toString()});
  rethrow;
}
```

### 4. Error Context

Provide rich context for error reporting:

```dart
await crashReporting.recordError(
  'Payment processing failed',
  context: 'Checkout flow',
  metadata: {
    'payment_method': 'credit_card',
    'amount': 9.99,
    'currency': 'USD',
    'user_id': userId,
    'retry_attempt': 2,
  },
);
```

### 5. Privacy Compliance

Respect user privacy and data protection:

```dart
// Only track necessary data
await analytics.logEvent('search', parameters: {
  'query_length': query.length, // Don't log actual query
  'results_count': results.length,
});

// Respect user consent
if (userConsentGiven) {
  await analytics.logEvent('user_action', parameters: {...});
}
```

## Configuration

### Environment-specific Settings

```dart
class MonitoringConfig {
  static bool get isEnabled {
    switch (AppConfig.environment) {
      case Environment.development:
        return false; // Disable in development
      case Environment.staging:
        return true; // Enable in staging
      case Environment.production:
        return true; // Enable in production
    }
  }
  
  static Duration get flushInterval {
    switch (AppConfig.environment) {
      case Environment.development:
        return Duration(minutes: 1);
      case Environment.staging:
        return Duration(minutes: 5);
      case Environment.production:
        return Duration(minutes: 10);
    }
  }
}
```

### Firebase Configuration

Ensure Firebase is properly configured:

```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.0.0
  firebase_crashlytics: ^3.0.0
```

```dart
// firebase_options.dart (generated)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Platform-specific configuration
  }
}
```

## Troubleshooting

### Common Issues

1. **Events not appearing in Firebase**
   - Check Firebase configuration
   - Verify analytics collection is enabled
   - Check network connectivity

2. **Performance data missing**
   - Ensure PerformanceMonitor is initialized
   - Check if monitoring is enabled
   - Verify device permissions

3. **Crash reports not sent**
   - Check Firebase Crashlytics configuration
   - Verify crashlytics collection is enabled
   - Check for network issues

### Debug Mode

Enable debug logging for troubleshooting:

```dart
// Enable debug mode
Logger.setLevel(LogLevel.debug);

// Check service status
final analytics = AnalyticsService();
print('Analytics enabled: ${analytics.isEnabled}');
print('Analytics initialized: ${analytics.isInitialized}');
```

## Analytics Dashboard

### Firebase Console

Access Firebase Analytics dashboard:
1. Go to Firebase Console
2. Select your project
3. Navigate to Analytics > Events
4. View real-time and historical data

### Custom Dashboards

Create custom dashboards using the monitoring data:

```dart
// Generate custom report
final report = await MonitoringDashboard().generateReport();

// Export data for external analysis
final data = report.historicalData;
final jsonData = jsonEncode(data);
// Send to external analytics service
```

## Future Enhancements

- [ ] Real-time alerting system
- [ ] Advanced performance profiling
- [ ] User journey tracking
- [ ] A/B testing integration
- [ ] Custom analytics dashboards
- [ ] Machine learning insights
- [ ] Automated performance optimization
- [ ] Predictive crash analysis
