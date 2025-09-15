import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Global error handler for the entire application
class GlobalErrorHandler {
  static bool _isInitialized = false;

  /// Initialize the global error handler
  static void initialize() {
    if (_isInitialized) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );

      // In debug mode, show the error in the console
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Handle platform errors (Android/iOS)
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.error(
        'Platform error',
        error: error,
        stackTrace: stack,
      );
      return true; // Indicate that we handled the error
    };

    _isInitialized = true;
    Logger.info('Global error handler initialized');
  }

  /// Handle errors from async operations
  static void handleAsyncError(Object error, StackTrace stackTrace, {String? context}) {
    Logger.error(
      context ?? 'Async operation error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Show a user-friendly error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (error != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a user-friendly error snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Object? error,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Handle network errors specifically
  static void handleNetworkError(BuildContext context, Object error) {
    String message;
    String title = 'Network Error';

    if (error.toString().contains('SocketException')) {
      message = 'Please check your internet connection and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'The request timed out. Please try again.';
    } else if (error.toString().contains('HandshakeException')) {
      message = 'Connection security error. Please try again.';
    } else {
      message = 'A network error occurred. Please try again.';
    }

    showErrorDialog(
      context,
      title: title,
      message: message,
      error: error,
    );
  }

  /// Handle authentication errors specifically
  static void handleAuthError(BuildContext context, Object error) {
    String message;
    String title = 'Authentication Error';

    if (error.toString().contains('user-not-found')) {
      message = 'User account not found. Please check your credentials.';
    } else if (error.toString().contains('wrong-password')) {
      message = 'Incorrect password. Please try again.';
    } else if (error.toString().contains('user-disabled')) {
      message = 'This account has been disabled. Please contact support.';
    } else if (error.toString().contains('too-many-requests')) {
      message = 'Too many failed attempts. Please try again later.';
    } else {
      message = 'An authentication error occurred. Please try again.';
    }

    showErrorDialog(
      context,
      title: title,
      message: message,
      error: error,
    );
  }

  /// Handle file operation errors specifically
  static void handleFileError(BuildContext context, Object error) {
    String message;
    String title = 'File Error';

    if (error.toString().contains('Permission denied')) {
      message = 'Permission denied. Please check app permissions.';
    } else if (error.toString().contains('No such file')) {
      message = 'File not found. Please try again.';
    } else if (error.toString().contains('No space left')) {
      message = 'Insufficient storage space. Please free up some space.';
    } else {
      message = 'A file operation error occurred. Please try again.';
    }

    showErrorDialog(
      context,
      title: title,
      message: message,
      error: error,
    );
  }

  /// Copy error details to clipboard
  static void copyErrorToClipboard(Object error, StackTrace? stackTrace) {
    final errorText = 'Error: $error\n\nStackTrace:\n$stackTrace';
    Clipboard.setData(ClipboardData(text: errorText));
  }
}

/// Extension on BuildContext for easy error handling
extension ErrorHandlingExtension on BuildContext {
  /// Show a network error dialog
  void showNetworkError(Object error) {
    GlobalErrorHandler.handleNetworkError(this, error);
  }

  /// Show an authentication error dialog
  void showAuthError(Object error) {
    GlobalErrorHandler.handleAuthError(this, error);
  }

  /// Show a file error dialog
  void showFileError(Object error) {
    GlobalErrorHandler.handleFileError(this, error);
  }

  /// Show a generic error dialog
  void showError({
    required String title,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    GlobalErrorHandler.showErrorDialog(
      this,
      title: title,
      message: message,
      error: error,
      stackTrace: stackTrace,
      onRetry: onRetry,
    );
  }

  /// Show an error snackbar
  void showErrorSnackBar({
    required String message,
    Object? error,
    VoidCallback? onRetry,
  }) {
    GlobalErrorHandler.showErrorSnackBar(
      this,
      message: message,
      error: error,
      onRetry: onRetry,
    );
  }
}
