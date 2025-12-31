import 'package:flutter/foundation.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  // Error logging callback (can be customized)
  Function(String message, dynamic error, StackTrace? stackTrace)? onError;

  /// Log an error with optional stack trace
  void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: $message');
      print('Details: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    
    // Call custom error handler if set
    onError?.call(message, error, stackTrace);
  }

  /// Get user-friendly error message from exception
  String getUserMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Database errors
    if (errorString.contains('no such table')) {
      return 'Database error: Missing table. Please restart the app.';
    }
    if (errorString.contains('foreign key constraint')) {
      return 'Cannot delete: This item is referenced by other records.';
    }
    if (errorString.contains('unique constraint')) {
      return 'This item already exists in the database.';
    }
    if (errorString.contains('not null constraint')) {
      return 'Required information is missing.';
    }

    // Network/connection errors
    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Network error: Please check your connection.';
    }

    // File system errors
    if (errorString.contains('permission denied')) {
      return 'Permission denied: Cannot access the file or directory.';
    }
    if (errorString.contains('no such file')) {
      return 'File not found.';
    }

    // Format errors
    if (errorString.contains('formatexception')) {
      return 'Invalid data format.';
    }

    // Default message
    return 'An error occurred: ${error.toString()}';
  }

  /// Wrap a database operation with error handling
  Future<T?> executeSafely<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logError(
        errorMessage ?? 'Error in $operationName',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Execute operation and return success status with optional result
  Future<OperationResult<T>> executeWithResult<T>({
    required Future<T> Function() operation,
    required String operationName,
  }) async {
    try {
      final result = await operation();
      return OperationResult.success(result);
    } catch (e, stackTrace) {
      logError('Error in $operationName', e, stackTrace);
      return OperationResult.failure(getUserMessage(e));
    }
  }
}

/// Result wrapper for operations
class OperationResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  OperationResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  OperationResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}
