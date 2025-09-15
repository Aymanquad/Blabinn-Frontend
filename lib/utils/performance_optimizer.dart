import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility class for performance optimizations
class PerformanceOptimizer {
  /// Wraps a widget with RepaintBoundary to prevent unnecessary repaints
  static Widget withRepaintBoundary(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Wraps a widget with AutomaticKeepAliveClientMixin for caching
  static Widget withKeepAlive(Widget child) {
    return _KeepAliveWrapper(child: child);
  }

  /// Creates an optimized list view with proper item extent
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double? itemExtent,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      controller: controller,
      padding: padding,
      // Performance optimizations
      cacheExtent: 250.0, // Cache 250 pixels worth of children
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }

  /// Creates an optimized grid view
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: gridDelegate,
      controller: controller,
      padding: padding,
      // Performance optimizations
      cacheExtent: 250.0,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }

  /// Debounces a function call to prevent excessive executions
  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _Debouncer.debounce(key, callback, delay: delay);
  }

  /// Throttles a function call to limit execution frequency
  static void throttle(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _Throttler.throttle(key, callback, delay: delay);
  }

  /// Creates a const widget when possible
  static Widget constWhenPossible(Widget child) {
    return child;
  }

  /// Wraps expensive operations in a performance boundary
  static Widget withPerformanceBoundary(
    Widget child, {
    String? debugLabel,
    bool enableRepaintBoundary = true,
    bool enableKeepAlive = false,
  }) {
    Widget result = child;

    if (enableKeepAlive) {
      result = withKeepAlive(result);
    }

    if (enableRepaintBoundary) {
      result = withRepaintBoundary(result, debugLabel: debugLabel);
    }

    return result;
  }
}

/// Internal wrapper for keep alive functionality
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Debouncer utility for preventing excessive function calls
class _Debouncer {
  static final Map<String, Timer> _timers = {};

  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
  }

  static void cancel(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// Throttler utility for limiting function call frequency
class _Throttler {
  static final Map<String, DateTime> _lastExecutions = {};

  static void throttle(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    final now = DateTime.now();
    final lastExecution = _lastExecutions[key];

    if (lastExecution == null || now.difference(lastExecution) >= delay) {
      _lastExecutions[key] = now;
      callback();
    }
  }

  static void reset(String key) {
    _lastExecutions.remove(key);
  }

  static void resetAll() {
    _lastExecutions.clear();
  }
}

/// Mixin for performance-optimized StatefulWidgets
mixin PerformanceOptimizedMixin<T extends StatefulWidget> on State<T> {
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, DateTime> _throttleTimers = {};

  /// Debounce a function call
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      if (mounted) {
        callback();
      }
      _debounceTimers.remove(key);
    });
  }

  /// Throttle a function call
  void throttle(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    final now = DateTime.now();
    final lastExecution = _throttleTimers[key];

    if (lastExecution == null || now.difference(lastExecution) >= delay) {
      _throttleTimers[key] = now;
      if (mounted) {
        callback();
      }
    }
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimers.clear();
    super.dispose();
  }
}

/// Extension on Widget for easy performance optimizations
extension PerformanceOptimizationExtension on Widget {
  /// Wraps widget with RepaintBoundary
  Widget withRepaintBoundary({String? debugLabel}) {
    return PerformanceOptimizer.withRepaintBoundary(this, debugLabel: debugLabel);
  }

  /// Wraps widget with keep alive
  Widget withKeepAlive() {
    return PerformanceOptimizer.withKeepAlive(this);
  }

  /// Wraps widget with performance boundary
  Widget withPerformanceBoundary({
    String? debugLabel,
    bool enableRepaintBoundary = true,
    bool enableKeepAlive = false,
  }) {
    return PerformanceOptimizer.withPerformanceBoundary(
      this,
      debugLabel: debugLabel,
      enableRepaintBoundary: enableRepaintBoundary,
      enableKeepAlive: enableKeepAlive,
    );
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start timing an operation
  static void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing an operation and record the duration
  static Duration endTiming(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return Duration.zero;

    final duration = DateTime.now().difference(startTime);
    _measurements.putIfAbsent(operation, () => []).add(duration);
    return duration;
  }

  /// Get average duration for an operation
  static Duration getAverageDuration(String operation) {
    final measurements = _measurements[operation];
    if (measurements == null || measurements.isEmpty) return Duration.zero;

    final totalMicroseconds = measurements
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    return Duration(microseconds: totalMicroseconds ~/ measurements.length);
  }

  /// Get all performance measurements
  static Map<String, Duration> getAllAverages() {
    return Map.fromEntries(
      _measurements.keys.map((key) => MapEntry(key, getAverageDuration(key))),
    );
  }

  /// Clear all measurements
  static void clearMeasurements() {
    _startTimes.clear();
    _measurements.clear();
  }
}
