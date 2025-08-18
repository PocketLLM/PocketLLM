import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ErrorType {
  network,
  authentication,
  validation,
  rateLimit,
  serverError,
  clientError,
  initialization,
  storage,
  unknown
}

enum ErrorSeverity {
  low,
  medium,
  high,
  critical
}

class ErrorAction {
  final String label;
  final VoidCallback action;
  final IconData icon;
  
  ErrorAction({
    required this.label,
    required this.action,
    required this.icon,
  });
}

class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String userMessage;
  final String? technicalDetails;
  final List<ErrorAction> suggestedActions;
  final DateTime timestamp;
  final String? context;
  final StackTrace? stackTrace;
  
  AppError({
    required this.type,
    required this.severity,
    required this.message,
    required this.userMessage,
    this.technicalDetails,
    this.suggestedActions = const [],
    required this.timestamp,
    this.context,
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }
  
  factory AppError.fromJson(Map<String, dynamic> json) {
    final errorService = ErrorService();
    return AppError(
      type: ErrorType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ErrorType.unknown,
      ),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.toString() == json['severity'],
        orElse: () => ErrorSeverity.medium,
      ),
      message: json['message'] ?? '',
      userMessage: json['userMessage'] ?? '',
      technicalDetails: json['technicalDetails'],
      suggestedActions: errorService._generateRecoveryActions(
        ErrorType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => ErrorType.unknown,
        ),
      ),
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
    );
  }
}

class ErrorService {
  static const String _errorLogKey = 'error_logs';
  static final ErrorService _instance = ErrorService._internal();
  
  // Private constructor
  ErrorService._internal();
  
  // Singleton pattern
  factory ErrorService() => _instance;
  
  // Enhanced error logging with classification
  Future<void> logError(String errorMessage, StackTrace? stackTrace, {
    ErrorType? type,
    ErrorSeverity? severity,
    String? context,
  }) async {
    final appError = _classifyError(errorMessage, stackTrace, type, severity, context);
    await _logAppError(appError);
  }
  
  // Log an AppError object
  Future<void> logAppError(AppError error) async {
    await _logAppError(error);
  }
  
  // Internal method to log AppError
  Future<void> _logAppError(AppError error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList(_errorLogKey) ?? [];
      
      errorLogs.add(jsonEncode(error.toJson()));
      
      // Keep only the most recent 100 errors
      if (errorLogs.length > 100) {
        errorLogs.removeAt(0);
      }
      
      await prefs.setStringList(_errorLogKey, errorLogs);
      
      // Print to console in debug mode
      if (kDebugMode) {
        print('ERROR [${error.type}/${error.severity}]: ${error.message}');
        if (error.context != null) {
          print('Context: ${error.context}');
        }
        if (error.stackTrace != null) {
          print(error.stackTrace);
        }
      }
    } catch (e) {
      // Fallback logging if there's an error with SharedPreferences
      if (kDebugMode) {
        print('Failed to log error: $e');
        print('Original error: ${error.message}');
      }
    }
  }
  
  // Classify error based on message and context
  AppError _classifyError(String errorMessage, StackTrace? stackTrace, 
      ErrorType? type, ErrorSeverity? severity, String? context) {
    
    final classifiedType = type ?? _determineErrorType(errorMessage);
    final classifiedSeverity = severity ?? _determineErrorSeverity(classifiedType, errorMessage);
    final userMessage = _generateUserFriendlyMessage(classifiedType, errorMessage);
    final actions = _generateRecoveryActions(classifiedType);
    
    return AppError(
      type: classifiedType,
      severity: classifiedSeverity,
      message: errorMessage,
      userMessage: userMessage,
      technicalDetails: stackTrace?.toString(),
      suggestedActions: actions,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: stackTrace,
    );
  }
  
  // Determine error type from error message
  ErrorType _determineErrorType(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    if (lowerMessage.contains('network') || 
        lowerMessage.contains('connection') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('socketexception')) {
      return ErrorType.network;
    }
    
    if (lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('authentication') ||
        lowerMessage.contains('api key') ||
        lowerMessage.contains('invalid key')) {
      return ErrorType.authentication;
    }
    
    if (lowerMessage.contains('validation') ||
        lowerMessage.contains('invalid input') ||
        lowerMessage.contains('format')) {
      return ErrorType.validation;
    }
    
    if (lowerMessage.contains('rate limit') ||
        lowerMessage.contains('too many requests') ||
        lowerMessage.contains('quota exceeded')) {
      return ErrorType.rateLimit;
    }
    
    if (lowerMessage.contains('server error') ||
        lowerMessage.contains('internal server') ||
        lowerMessage.contains('500') ||
        lowerMessage.contains('502') ||
        lowerMessage.contains('503')) {
      return ErrorType.serverError;
    }
    
    if (lowerMessage.contains('initialization') ||
        lowerMessage.contains('startup')) {
      return ErrorType.initialization;
    }
    
    if (lowerMessage.contains('storage') ||
        lowerMessage.contains('database') ||
        lowerMessage.contains('file')) {
      return ErrorType.storage;
    }
    
    return ErrorType.unknown;
  }
  
  // Determine error severity
  ErrorSeverity _determineErrorSeverity(ErrorType type, String errorMessage) {
    switch (type) {
      case ErrorType.initialization:
      case ErrorType.storage:
        return ErrorSeverity.critical;
      case ErrorType.authentication:
      case ErrorType.serverError:
        return ErrorSeverity.high;
      case ErrorType.network:
      case ErrorType.rateLimit:
        return ErrorSeverity.medium;
      case ErrorType.validation:
      case ErrorType.clientError:
        return ErrorSeverity.low;
      default:
        return ErrorSeverity.medium;
    }
  }
  
  // Generate user-friendly error messages
  String _generateUserFriendlyMessage(ErrorType type, String originalMessage) {
    switch (type) {
      case ErrorType.network:
        return 'Unable to connect to the internet. Please check your network connection and try again.';
      case ErrorType.authentication:
        return 'Authentication failed. Please check your API keys in settings and try again.';
      case ErrorType.validation:
        return 'Invalid input provided. Please check your input and try again.';
      case ErrorType.rateLimit:
        return 'Too many requests sent. Please wait a moment before trying again.';
      case ErrorType.serverError:
        return 'The server is experiencing issues. Please try again later.';
      case ErrorType.clientError:
        return 'There was an issue with your request. Please try again.';
      case ErrorType.initialization:
        return 'The app failed to start properly. Please restart the app.';
      case ErrorType.storage:
        return 'Unable to save or load data. Please check your device storage.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  // Generate recovery actions based on error type
  List<ErrorAction> _generateRecoveryActions(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return [
          ErrorAction(
            label: 'Check Connection',
            action: () {}, // Will be implemented in UI
            icon: Icons.wifi,
          ),
          ErrorAction(
            label: 'Retry',
            action: () {},
            icon: Icons.refresh,
          ),
        ];
      case ErrorType.authentication:
        return [
          ErrorAction(
            label: 'Check API Keys',
            action: () {},
            icon: Icons.key,
          ),
          ErrorAction(
            label: 'Settings',
            action: () {},
            icon: Icons.settings,
          ),
        ];
      case ErrorType.rateLimit:
        return [
          ErrorAction(
            label: 'Wait and Retry',
            action: () {},
            icon: Icons.schedule,
          ),
        ];
      case ErrorType.initialization:
        return [
          ErrorAction(
            label: 'Restart App',
            action: () {},
            icon: Icons.restart_alt,
          ),
        ];
      default:
        return [
          ErrorAction(
            label: 'Retry',
            action: () {},
            icon: Icons.refresh,
          ),
        ];
    }
  }
  
  // Get all error logs as AppError objects
  Future<List<AppError>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList(_errorLogKey) ?? [];
      
      return errorLogs
          .map((log) => AppError.fromJson(jsonDecode(log) as Map<String, dynamic>))
          .toList()
          .reversed // Most recent first
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get error logs: $e');
      }
      return [];
    }
  }
  
  // Get error logs filtered by type
  Future<List<AppError>> getErrorLogsByType(ErrorType type) async {
    final allErrors = await getErrorLogs();
    return allErrors.where((error) => error.type == type).toList();
  }
  
  // Get error logs filtered by severity
  Future<List<AppError>> getErrorLogsBySeverity(ErrorSeverity severity) async {
    final allErrors = await getErrorLogs();
    return allErrors.where((error) => error.severity == severity).toList();
  }
  
  // Get recent critical errors
  Future<List<AppError>> getCriticalErrors({int limit = 10}) async {
    final allErrors = await getErrorLogs();
    return allErrors
        .where((error) => error.severity == ErrorSeverity.critical)
        .take(limit)
        .toList();
  }
  
  // Clear all error logs
  Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear error logs: $e');
      }
    }
  }
  
  // Show enhanced error dialog with recovery actions
  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.severity),
            ),
            const SizedBox(width: 8),
            Text(
              _getErrorTitle(error.type),
              style: TextStyle(color: _getErrorColor(error.severity)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            if (error.technicalDetails != null && kDebugMode) ...[
              const SizedBox(height: 16),
              const Text(
                'Technical Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                error.technicalDetails!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        actions: [
          ...error.suggestedActions.map((action) => TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              action.action();
            },
            icon: Icon(action.icon),
            label: Text(action.label),
          )),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Show simple error dialog with message
  static void showSimpleErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Show enhanced error snackbar
  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(error.userMessage)),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        duration: Duration(seconds: error.severity == ErrorSeverity.critical ? 10 : 5),
        action: error.suggestedActions.isNotEmpty
            ? SnackBarAction(
                label: error.suggestedActions.first.label,
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  error.suggestedActions.first.action();
                },
              )
            : SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }
  
  // Show simple error snackbar with message
  static void showSimpleErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // Helper methods for UI
  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.key_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.rateLimit:
        return Icons.schedule;
      case ErrorType.serverError:
        return Icons.dns;
      case ErrorType.clientError:
        return Icons.error_outline;
      case ErrorType.initialization:
        return Icons.error;
      case ErrorType.storage:
        return Icons.storage;
      default:
        return Icons.error_outline;
    }
  }
  
  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.deepOrange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red[900]!;
    }
  }
  
  static String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.rateLimit:
        return 'Rate Limit Exceeded';
      case ErrorType.serverError:
        return 'Server Error';
      case ErrorType.clientError:
        return 'Client Error';
      case ErrorType.initialization:
        return 'Initialization Error';
      case ErrorType.storage:
        return 'Storage Error';
      default:
        return 'Error';
    }
  }
  
  // Retry mechanism with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
  }
} 