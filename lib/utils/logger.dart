import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A comprehensive logging utility for the Chatify app
/// Replaces all print() statements with proper logging levels
class Logger {
  static const String _tag = 'Chatify';
  
  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final logTag = tag != null ? '$_tag.$tag' : _tag;
      developer.log(
        message,
        name: logTag,
        level: 500, // DEBUG level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Log info messages
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag != null ? '$_tag.$tag' : _tag;
    developer.log(
      message,
      name: logTag,
      level: 800, // INFO level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag != null ? '$_tag.$tag' : _tag;
    developer.log(
      message,
      name: logTag,
      level: 900, // WARNING level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag != null ? '$_tag.$tag' : _tag;
    developer.log(
      message,
      name: logTag,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log API requests
  static void apiRequest(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final message = 'API Request: $method $endpoint';
      final details = data != null ? '\nData: $data' : '';
      debug('$message$details', tag: 'API');
    }
  }
  
  /// Log API responses
  static void apiResponse(String method, String endpoint, int statusCode, {String? body}) {
    if (kDebugMode) {
      final message = 'API Response: $method $endpoint -> $statusCode';
      final details = body != null ? '\nBody: $body' : '';
      debug('$message$details', tag: 'API');
    }
  }
  
  /// Log authentication events
  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, tag: 'AUTH', error: error, stackTrace: stackTrace);
  }
  
  /// Log socket events
  static void socket(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debug(message, tag: 'SOCKET', error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log notification events
  static void notification(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, tag: 'NOTIFICATION', error: error, stackTrace: stackTrace);
  }
  
  /// Log billing/payment events
  static void billing(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, tag: 'BILLING', error: error, stackTrace: stackTrace);
  }
  
  /// Log ad events
  static void ads(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debug(message, tag: 'ADS', error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log performance metrics
  static void performance(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debug(message, tag: 'PERFORMANCE', error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      final message = 'User Action: $action';
      final details = metadata != null ? '\nMetadata: $metadata' : '';
      debug('$message$details', tag: 'USER');
    }
  }
}
