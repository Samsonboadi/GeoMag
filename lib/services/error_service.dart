// lib/services/error_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/modern_feedback.dart';

class ErrorService {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showToUser = true,
  }) {
    // Log error for debugging
    if (kDebugMode) {
      print('Error occurred: $error');
    }

    // Show user-friendly message
    if (showToUser && context.mounted) {
      final message = customMessage ?? _getUserFriendlyMessage(error);
      ModernFeedback.showError(context, message);
    }
  }

  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission')) {
      return 'Permission required. Please check app settings.';
    }
    
    if (errorString.contains('location')) {
      return 'Location services unavailable. Check GPS settings.';
    }
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Check internet connectivity.';
    }
    
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return 'Database error. Data may not be saved properly.';
    }
    
    if (errorString.contains('file') || errorString.contains('storage')) {
      return 'File system error. Check storage permissions.';
    }
    
    if (errorString.contains('sensor') || errorString.contains('magnetometer')) {
      return 'Sensor unavailable. Try restarting the app.';
    }
    
    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }
}

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

class LocationException extends AppException {
  const LocationException(String message) : super(message, code: 'LOCATION_ERROR');
}

class DatabaseException extends AppException {
  const DatabaseException(String message) : super(message, code: 'DATABASE_ERROR');
}

class SensorException extends AppException {
  const SensorException(String message) : super(message, code: 'SENSOR_ERROR');
}

class ExportException extends AppException {
  const ExportException(String message) : super(message, code: 'EXPORT_ERROR');
}

// Extension to add error handling to Future
extension FutureErrorHandling<T> on Future<T> {
  Future<T> handleError(
    BuildContext context, {
    String? customMessage,
    bool showToUser = true,
  }) async {
    try {
      return await this;
    } catch (error) {
      ErrorService.handleError(
        context,
        error,
        customMessage: customMessage,
        showToUser: showToUser,
      );
      rethrow;
    }
  }
  
  Future<T?> handleErrorSafely(
    BuildContext context, {
    String? customMessage,
    bool showToUser = true,
  }) async {
    try {
      return await this;
    } catch (error) {
      ErrorService.handleError(
        context,
        error,
        customMessage: customMessage,
        showToUser: showToUser,
      );
      return null;
    }
  }
}

// Global error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _defaultErrorWidget(_error!);
    }
    
    return widget.child;
  }

  Widget _defaultErrorWidget(Object error) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'The app encountered an unexpected error. Please restart the app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
                onPressed: () {
                  setState(() => _error = null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Logging service for debugging
class LogService {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] ${tag ?? 'APP'}: $message');
    }
  }
  
  static void logError(dynamic error, {String? tag, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] ${tag ?? 'ERROR'}: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      print('PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
}

// Performance monitoring mixin
mixin PerformanceMonitor<T extends StatefulWidget> on State<T> {
  final Map<String, DateTime> _startTimes = {};
  
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }
  
  void endTimer(String operation) {
    final start = _startTimes[operation];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      LogService.logPerformance(operation, duration);
      _startTimes.remove(operation);
    }
  }
}