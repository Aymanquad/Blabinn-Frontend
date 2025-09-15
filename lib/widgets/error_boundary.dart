import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../utils/logger.dart';

/// A widget that catches and handles errors in its child widget tree
/// Provides a fallback UI when errors occur and logs them appropriately
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorTitle,
    this.errorMessage,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String? errorDetails;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            widget.errorTitle ?? 'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'An unexpected error occurred. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _reportError,
                icon: const Icon(Icons.bug_report),
                label: const Text('Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      hasError = false;
      errorDetails = null;
    });
  }

  void _reportError() {
    // Copy error details to clipboard
    if (errorDetails != null) {
      Clipboard.setData(ClipboardData(text: errorDetails!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error details copied to clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      hasError = true;
      errorDetails = 'Error: $error\nStackTrace: $stackTrace';
    });

    // Log the error
    Logger.error(
      'Error boundary caught error',
      error: error,
      stackTrace: stackTrace,
    );

    // Call custom error handler if provided
    widget.onError?.call();
  }
}

/// A wrapper that catches errors in widget building
class ErrorCatcher extends StatelessWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  const ErrorCatcher({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (error, stackTrace) {
      Logger.error(
        'Error caught in ErrorCatcher',
        error: error,
        stackTrace: stackTrace,
      );

      if (errorBuilder != null) {
        return errorBuilder!(error, stackTrace);
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Widget Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to render widget: ${error.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

/// A mixin that provides error handling capabilities to StatefulWidgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void handleError(Object error, StackTrace stackTrace, {String? context}) {
    Logger.error(
      context ?? 'Error in ${T.toString()}',
      error: error,
      stackTrace: stackTrace,
    );

    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${error.toString()}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Details',
            textColor: Colors.white,
            onPressed: () => _showErrorDialog(error, stackTrace),
          ),
        ),
      );
    }
  }

  void _showErrorDialog(Object error, StackTrace stackTrace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Stack Trace:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stackTrace.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Error: $error\nStackTrace: $stackTrace',
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error details copied to clipboard'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// A utility class for handling async operations with proper error handling
class SafeAsync {
  /// Executes an async operation with error handling
  static Future<T?> execute<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
    Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      Logger.error(
        context ?? 'SafeAsync operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      
      onError?.call(error, stackTrace);
      return fallback;
    }
  }

  /// Executes an async operation and returns a Result object
  static Future<Result<T>> executeWithResult<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      Logger.error(
        context ?? 'SafeAsync operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result.failure(error, stackTrace);
    }
  }
}

/// A result class for handling success/failure states
class Result<T> {
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    this.stackTrace,
    required this.isSuccess,
  });

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.failure(Object error, StackTrace stackTrace) {
    return Result._(
      error: error,
      stackTrace: stackTrace,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;

  /// Returns the data if successful, otherwise throws the error
  T get value {
    if (isSuccess) {
      return data as T;
    }
    throw error!;
  }

  /// Returns the data if successful, otherwise returns the provided fallback
  T getOrElse(T fallback) {
    return isSuccess ? data as T : fallback;
  }

  /// Transforms the result if successful
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(data as T));
      } catch (error, stackTrace) {
        return Result.failure(error, stackTrace);
      }
    }
    return Result.failure(error!, stackTrace!);
  }
}
