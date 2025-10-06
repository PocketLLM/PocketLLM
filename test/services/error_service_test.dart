import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketllm/services/error_service.dart';

void main() {
  group('ErrorService', () {
    late ErrorService errorService;

    setUp(() {
      errorService = ErrorService();
      SharedPreferences.setMockInitialValues({});
    });

    group('Error Classification', () {
      test('should classify network errors correctly', () async {
        await errorService.logError(
          'SocketException: Connection failed',
          StackTrace.current,
          type: ErrorType.network,
        );

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        expect(logs.first.type, ErrorType.network);
        expect(logs.first.severity, ErrorSeverity.medium);
        expect(logs.first.userMessage, contains('network connection'));
      });

      test('should classify authentication errors correctly', () async {
        await errorService.logError(
          'Unauthorized: Invalid API key',
          StackTrace.current,
          type: ErrorType.authentication,
        );

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        expect(logs.first.type, ErrorType.authentication);
        expect(logs.first.severity, ErrorSeverity.high);
        expect(logs.first.userMessage, contains('API keys'));
      });

      test('should classify rate limit errors correctly', () async {
        await errorService.logError(
          'Rate limit exceeded: Too many requests',
          StackTrace.current,
          type: ErrorType.rateLimit,
        );

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        expect(logs.first.type, ErrorType.rateLimit);
        expect(logs.first.severity, ErrorSeverity.medium);
        expect(logs.first.userMessage, contains('Too many requests'));
      });

      test('should classify initialization errors as critical', () async {
        await errorService.logError(
          'Initialization failed: Unable to start services',
          StackTrace.current,
          type: ErrorType.initialization,
        );

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        expect(logs.first.type, ErrorType.initialization);
        expect(logs.first.severity, ErrorSeverity.critical);
      });
    });

    group('Error Logging', () {
      test('should log errors with all required fields', () async {
        final stackTrace = StackTrace.current;
        await errorService.logError(
          'Test error message',
          stackTrace,
          context: 'Test context',
        );

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        
        final error = logs.first;
        expect(error.message, 'Test error message');
        expect(error.context, 'Test context');
        expect(error.technicalDetails, isNotNull);
        expect(error.timestamp, isA<DateTime>());
      });

      test('should log AppError objects directly', () async {
        final appError = AppError(
          type: ErrorType.validation,
          severity: ErrorSeverity.low,
          message: 'Validation failed',
          userMessage: 'Please check your input',
          timestamp: DateTime.now(),
          context: 'Form validation',
        );

        await errorService.logAppError(appError);

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 1);
        expect(logs.first.type, ErrorType.validation);
        expect(logs.first.message, 'Validation failed');
        expect(logs.first.userMessage, 'Please check your input');
      });

      test('should limit error logs to 100 entries', () async {
        // Add 105 errors
        for (int i = 0; i < 105; i++) {
          await errorService.logError('Error $i', null);
        }

        final logs = await errorService.getErrorLogs();
        expect(logs.length, 100);
        
        // Should keep the most recent errors
        expect(logs.first.message, 'Error 104');
        expect(logs.last.message, 'Error 5');
      });
    });

    group('Error Filtering', () {
      setUp(() async {
        // Add various types of errors
        await errorService.logError('Network error', null, type: ErrorType.network);
        await errorService.logError('Auth error', null, type: ErrorType.authentication);
        await errorService.logError('Critical error', null, 
            type: ErrorType.initialization, severity: ErrorSeverity.critical);
        await errorService.logError('Low priority error', null, 
            type: ErrorType.validation, severity: ErrorSeverity.low);
      });

      test('should filter errors by type', () async {
        final networkErrors = await errorService.getErrorLogsByType(ErrorType.network);
        expect(networkErrors.length, 1);
        expect(networkErrors.first.type, ErrorType.network);

        final authErrors = await errorService.getErrorLogsByType(ErrorType.authentication);
        expect(authErrors.length, 1);
        expect(authErrors.first.type, ErrorType.authentication);
      });

      test('should filter errors by severity', () async {
        final criticalErrors = await errorService.getErrorLogsBySeverity(ErrorSeverity.critical);
        expect(criticalErrors.length, 1);
        expect(criticalErrors.first.severity, ErrorSeverity.critical);

        final lowErrors = await errorService.getErrorLogsBySeverity(ErrorSeverity.low);
        expect(lowErrors.length, 1);
        expect(lowErrors.first.severity, ErrorSeverity.low);
      });

      test('should get critical errors with limit', () async {
        final criticalErrors = await errorService.getCriticalErrors(limit: 5);
        expect(criticalErrors.length, 1);
        expect(criticalErrors.first.severity, ErrorSeverity.critical);
      });
    });

    group('Error Recovery Actions', () {
      test('should generate appropriate recovery actions for network errors', () async {
        await errorService.logError('Network error', null, type: ErrorType.network);
        
        final logs = await errorService.getErrorLogs();
        final actions = logs.first.suggestedActions;
        
        expect(actions.length, 2);
        expect(actions.any((action) => action.label == 'Check Connection'), true);
        expect(actions.any((action) => action.label == 'Retry'), true);
      });

      test('should generate appropriate recovery actions for auth errors', () async {
        await errorService.logError('Auth error', null, type: ErrorType.authentication);
        
        final logs = await errorService.getErrorLogs();
        final actions = logs.first.suggestedActions;
        
        expect(actions.length, 2);
        expect(actions.any((action) => action.label == 'Check API Keys'), true);
        expect(actions.any((action) => action.label == 'Settings'), true);
      });
    });

    group('Retry Mechanism', () {
      test('should succeed on first attempt', () async {
        int callCount = 0;
        
        final result = await ErrorService.retryWithBackoff(() async {
          callCount++;
          return 'success';
        });
        
        expect(result, 'success');
        expect(callCount, 1);
      });

      test('should retry on failure and eventually succeed', () async {
        int callCount = 0;
        
        final result = await ErrorService.retryWithBackoff(
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('Temporary failure');
            }
            return 'success';
          },
          initialDelay: Duration.zero, // Speed up test
        );
        
        expect(result, 'success');
        expect(callCount, 3);
      });

      test('should fail after max retries', () async {
        int callCount = 0;
        
        try {
          await ErrorService.retryWithBackoff(
            () async {
              callCount++;
              throw Exception('Persistent failure');
            },
            maxRetries: 2,
            initialDelay: Duration.zero, // Speed up test
          );
          fail('Should have thrown an exception');
        } catch (e) {
          // Expected to throw
        }
        
        expect(callCount, 2);
      });
    });

    group('Error Persistence', () {
      test('should persist and retrieve errors correctly', () async {
        await errorService.logError('Test error', null, context: 'Test context');
        
        // Create new instance to test persistence
        final newErrorService = ErrorService();
        final logs = await newErrorService.getErrorLogs();
        
        expect(logs.length, 1);
        expect(logs.first.message, 'Test error');
        expect(logs.first.context, 'Test context');
      });

      test('should clear all error logs', () async {
        await errorService.logError('Error 1', null);
        await errorService.logError('Error 2', null);
        
        var logs = await errorService.getErrorLogs();
        expect(logs.length, 2);
        
        await errorService.clearErrorLogs();
        logs = await errorService.getErrorLogs();
        expect(logs.length, 0);
      });
    });
  });
}