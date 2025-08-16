import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler extends ChangeNotifier {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<AppError> _errors = [];
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _errorCooldown = Duration(minutes: 5);

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errors => List.unmodifiable(_errors);

  void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
    bool showToUser = true,
    VoidCallback? onRetry,
  }) {
    final appError = AppError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
      showToUser: showToUser,
      onRetry: onRetry,
    );

    _addError(appError);

    if (showToUser) {
      _showErrorToUser(appError);
    }

    // Log error for debugging
    if (kDebugMode) {
      print('Error: ${appError.message}');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  void _addError(AppError error) {
    _errors.add(error);
    _errorController.add(error);
    notifyListeners();

    // Keep only last 100 errors
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }

    // Track error frequency
    final errorKey = '${error.context}_${error.error.runtimeType}';
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTimes[errorKey] = DateTime.now();
  }

  void _showErrorToUser(AppError error) {
    // Show snackbar or dialog based on severity
    switch (error.severity) {
      case ErrorSeverity.info:
        _showInfoSnackBar(error);
        break;
      case ErrorSeverity.warning:
        _showWarningSnackBar(error);
        break;
      case ErrorSeverity.error:
        _showErrorSnackBar(error);
        break;
      case ErrorSeverity.critical:
        _showCriticalDialog(error);
        break;
    }
  }

  void _showInfoSnackBar(AppError error) {
    // Implementation would depend on having access to BuildContext
    // This is a placeholder for the actual implementation
  }

  void _showWarningSnackBar(AppError error) {
    // Implementation would depend on having access to BuildContext
  }

  void _showErrorSnackBar(AppError error) {
    // Implementation would depend on having access to BuildContext
  }

  void _showCriticalDialog(AppError error) {
    // Implementation would depend on having access to BuildContext
  }

  Future<T?> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = _maxRetries,
    Duration delay = _retryDelay,
    String? context,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        handleError(
          error,
          stackTrace,
          context: context,
          severity: ErrorSeverity.warning,
          showToUser: false,
        );

        if (attempts >= maxRetries) {
          handleError(
            error,
            stackTrace,
            context: context,
            severity: ErrorSeverity.error,
            showToUser: true,
          );
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay * attempts); // Exponential backoff
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }

  bool shouldRetry(String errorKey) {
    final count = _errorCounts[errorKey] ?? 0;
    final lastError = _lastErrorTimes[errorKey];
    
    if (count >= _maxRetries) {
      if (lastError != null) {
        final timeSinceLastError = DateTime.now().difference(lastError);
        if (timeSinceLastError < _errorCooldown) {
          return false; // Still in cooldown period
        } else {
          // Reset count after cooldown
          _errorCounts[errorKey] = 0;
          return true;
        }
      }
      return false;
    }
    
    return true;
  }

  void clearErrors() {
    _errors.clear();
    _errorCounts.clear();
    _lastErrorTimes.clear();
    notifyListeners();
  }

  void clearError(String errorKey) {
    _errors.removeWhere((error) => 
      '${error.context}_${error.error.runtimeType}' == errorKey
    );
    _errorCounts.remove(errorKey);
    _lastErrorTimes.remove(errorKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _errorController.close();
    super.dispose();
  }
}

class AppError {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final bool showToUser;
  final VoidCallback? onRetry;

  const AppError({
    required this.error,
    this.stackTrace,
    this.context,
    required this.severity,
    required this.timestamp,
    this.showToUser = true,
    this.onRetry,
  });

  String get message {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return error?.toString() ?? 'Unknown error';
  }

  String get title {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  IconData get icon {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info;
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

// Global error handler instance
final errorHandler = ErrorHandler();