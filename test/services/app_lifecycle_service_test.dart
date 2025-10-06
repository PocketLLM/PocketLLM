import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:pocketllm/services/app_lifecycle_service.dart';

void main() {
  group('AppLifecycleService', () {
    late AppLifecycleService appLifecycleService;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      appLifecycleService = AppLifecycleService();
    });

    group('ServiceInitializationResult', () {
      test('should create ServiceInitializationResult with required fields', () {
        final result = ServiceInitializationResult(
          serviceName: 'TestService',
          success: true,
          initializationTime: const Duration(milliseconds: 100),
        );

        expect(result.serviceName, 'TestService');
        expect(result.success, true);
        expect(result.error, isNull);
        expect(result.initializationTime, const Duration(milliseconds: 100));
      });

      test('should create ServiceInitializationResult with error', () {
        final result = ServiceInitializationResult(
          serviceName: 'TestService',
          success: false,
          error: 'Test error',
          initializationTime: const Duration(milliseconds: 50),
        );

        expect(result.serviceName, 'TestService');
        expect(result.success, false);
        expect(result.error, 'Test error');
        expect(result.initializationTime, const Duration(milliseconds: 50));
      });
    });

    group('Initialization Status', () {
      test('should have initial not started status', () {
        expect(appLifecycleService.initializationStatus, InitializationStatus.notStarted);
        expect(appLifecycleService.isInitialized, false);
        expect(appLifecycleService.hasInitializationErrors, false);
      });

      test('should initialize app services', () async {
        final success = await appLifecycleService.initializeApp();
        
        expect(success, isA<bool>());
        expect(appLifecycleService.initializationStatus, 
               anyOf(InitializationStatus.completed, InitializationStatus.failed));
        expect(appLifecycleService.initializationResults, isNotEmpty);
      });

      test('should not allow concurrent initialization', () async {
        // Start first initialization
        final future1 = appLifecycleService.initializeApp();
        
        // Try to start second initialization
        final result2 = await appLifecycleService.initializeApp();
        
        // Second call should return false (already in progress)
        expect(result2, false);
        
        // Wait for first initialization to complete
        await future1;
      });
    });

    group('Service Management', () {
      test('should track initialization results', () async {
        await appLifecycleService.initializeApp();
        
        final results = appLifecycleService.initializationResults;
        expect(results, isNotEmpty);
        
        for (final result in results) {
          expect(result.serviceName, isNotEmpty);
          expect(result.initializationTime, greaterThan(Duration.zero));
        }
      });

      test('should provide initialization summary', () async {
        await appLifecycleService.initializeApp();
        
        final summary = appLifecycleService.getInitializationSummary();
        
        expect(summary['status'], contains('InitializationStatus.'));
        expect(summary['totalServices'], isA<int>());
        expect(summary['successfulServices'], isA<int>());
        expect(summary['failedServices'], isA<int>());
        expect(summary['totalInitializationTime'], isA<int>());
        expect(summary['results'], isA<List>());
      });

      test('should allow restart initialization', () async {
        // First initialization
        await appLifecycleService.initializeApp();
        final firstResults = appLifecycleService.initializationResults.length;
        
        // Restart initialization
        final success = await appLifecycleService.restartInitialization();
        
        expect(success, isA<bool>());
        expect(appLifecycleService.initializationResults.length, 
               greaterThanOrEqualTo(firstResults));
      });
    });

    group('Lifecycle State Management', () {
      test('should have initial detached state', () {
        expect(appLifecycleService.currentState, AppLifecycleState.detached);
      });

      test('should handle lifecycle state changes', () {
        bool notified = false;
        appLifecycleService.addListener(() {
          notified = true;
        });

        // Simulate lifecycle state change
        appLifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(appLifecycleService.currentState, AppLifecycleState.resumed);
        expect(notified, true);
      });

      test('should handle all lifecycle states', () {
        final states = [
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
          AppLifecycleState.paused,
          AppLifecycleState.detached,
          AppLifecycleState.hidden,
        ];

        for (final state in states) {
          appLifecycleService.didChangeAppLifecycleState(state);
          expect(appLifecycleService.currentState, state);
        }
      });
    });

    group('Service Instance Management', () {
      test('should store and retrieve service instances', () async {
        await appLifecycleService.initializeApp();
        
        // Try to get a service instance
        final errorService = appLifecycleService.getService<dynamic>('ErrorService');
        expect(errorService, isNotNull);
      });

      test('should return null for non-existent service', () {
        final nonExistentService = appLifecycleService.getService<dynamic>('NonExistentService');
        expect(nonExistentService, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // The service should handle errors and continue with other services
        final success = await appLifecycleService.initializeApp();
        
        // Even if some services fail, the method should complete
        expect(success, isA<bool>());
        expect(appLifecycleService.initializationStatus, 
               anyOf(InitializationStatus.completed, InitializationStatus.failed));
      });
    });
  });
}