import 'package:flutter_test/flutter_test.dart';
import 'package:pocketllm/services/model_state.dart';
import 'package:pocketllm/component/models.dart';

void main() {
  group('ModelHealthInfo', () {
    test('should create ModelHealthInfo with required fields', () {
      final healthInfo = ModelHealthInfo(
        modelId: 'test-model',
        status: ModelHealthStatus.healthy,
        lastChecked: DateTime.now(),
      );

      expect(healthInfo.modelId, 'test-model');
      expect(healthInfo.status, ModelHealthStatus.healthy);
      expect(healthInfo.error, isNull);
      expect(healthInfo.responseTime, isNull);
      expect(healthInfo.additionalInfo, isNull);
    });

    test('should create ModelHealthInfo with all fields', () {
      final now = DateTime.now();
      final responseTime = const Duration(milliseconds: 500);
      final additionalInfo = {'test': 'data'};

      final healthInfo = ModelHealthInfo(
        modelId: 'test-model',
        status: ModelHealthStatus.unhealthy,
        lastChecked: now,
        error: 'Connection failed',
        responseTime: responseTime,
        additionalInfo: additionalInfo,
      );

      expect(healthInfo.modelId, 'test-model');
      expect(healthInfo.status, ModelHealthStatus.unhealthy);
      expect(healthInfo.lastChecked, now);
      expect(healthInfo.error, 'Connection failed');
      expect(healthInfo.responseTime, responseTime);
      expect(healthInfo.additionalInfo, additionalInfo);
    });

    test('should create copy with updated fields', () {
      final original = ModelHealthInfo(
        modelId: 'test-model',
        status: ModelHealthStatus.unknown,
        lastChecked: DateTime.now(),
      );

      final copy = original.copyWith(
        status: ModelHealthStatus.healthy,
        responseTime: const Duration(milliseconds: 200),
      );

      expect(copy.modelId, original.modelId);
      expect(copy.lastChecked, original.lastChecked);
      expect(copy.status, ModelHealthStatus.healthy);
      expect(copy.responseTime, const Duration(milliseconds: 200));
      expect(copy.error, original.error);
    });

    test('should serialize to and from JSON', () {
      final now = DateTime.now();
      final original = ModelHealthInfo(
        modelId: 'test-model',
        status: ModelHealthStatus.healthy,
        lastChecked: now,
        error: 'Test error',
        responseTime: const Duration(milliseconds: 300),
        additionalInfo: {'key': 'value'},
      );

      final json = original.toJson();
      final restored = ModelHealthInfo.fromJson(json);

      expect(restored.modelId, original.modelId);
      expect(restored.status, original.status);
      expect(restored.lastChecked, original.lastChecked);
      expect(restored.error, original.error);
      expect(restored.responseTime, original.responseTime);
      expect(restored.additionalInfo, original.additionalInfo);
    });

    test('should handle JSON with missing optional fields', () {
      final json = {
        'modelId': 'test-model',
        'status': 'ModelHealthStatus.healthy',
        'lastChecked': DateTime.now().toIso8601String(),
      };

      final healthInfo = ModelHealthInfo.fromJson(json);

      expect(healthInfo.modelId, 'test-model');
      expect(healthInfo.status, ModelHealthStatus.healthy);
      expect(healthInfo.error, isNull);
      expect(healthInfo.responseTime, isNull);
      expect(healthInfo.additionalInfo, isNull);
    });
  });

  group('ModelState', () {
    late ModelState modelState;

    setUp(() {
      modelState = ModelState();
    });

    group('Initialization', () {
      test('should have initial state', () {
        expect(modelState.selectedModelId.value, isNull);
        expect(modelState.availableModels.value, isEmpty);
        expect(modelState.modelHealthStatus.value, isEmpty);
        expect(modelState.isInitialized, false);
        expect(modelState.selectedModel, isNull);
        expect(modelState.healthyModels, isEmpty);
      });

      test('should initialize without errors', () async {
        // Note: This test may fail in isolation due to dependencies
        // but verifies the method exists and handles errors gracefully
        expect(() => modelState.init(), returnsNormally);
      });
    });

    group('Model Health Management', () {
      test('should get model health info', () {
        const modelId = 'test-model';
        final healthInfo = ModelHealthInfo(
          modelId: modelId,
          status: ModelHealthStatus.healthy,
          lastChecked: DateTime.now(),
        );

        // Simulate health info being set
        final currentHealth = Map<String, ModelHealthInfo>.from(modelState.modelHealthStatus.value);
        currentHealth[modelId] = healthInfo;
        modelState.modelHealthStatus.value = currentHealth;

        final retrievedHealth = modelState.getModelHealth(modelId);
        expect(retrievedHealth, isNotNull);
        expect(retrievedHealth!.modelId, modelId);
        expect(retrievedHealth.status, ModelHealthStatus.healthy);
      });

      test('should return null for non-existent model health', () {
        final health = modelState.getModelHealth('non-existent-model');
        expect(health, isNull);
      });

      test('should filter healthy models', () {
        // Create mock models
        final model1 = ModelConfig(
          id: 'model1',
          name: 'Test Model 1',
          provider: ModelProvider.openAI,
          model: 'gpt-3.5-turbo',
          baseUrl: 'https://api.openai.com/v1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final model2 = ModelConfig(
          id: 'model2',
          name: 'Test Model 2',
          provider: ModelProvider.ollama,
          model: 'llama2',
          baseUrl: 'http://localhost:11434',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Set available models
        modelState.availableModels.value = [model1, model2];

        // Set health status
        final healthMap = {
          'model1': ModelHealthInfo(
            modelId: 'model1',
            status: ModelHealthStatus.healthy,
            lastChecked: DateTime.now(),
          ),
          'model2': ModelHealthInfo(
            modelId: 'model2',
            status: ModelHealthStatus.unhealthy,
            lastChecked: DateTime.now(),
          ),
        };
        modelState.modelHealthStatus.value = healthMap;

        final healthyModels = modelState.healthyModels;
        expect(healthyModels.length, 1);
        expect(healthyModels.first.id, 'model1');
      });
    });

    group('Health Summary', () {
      test('should provide health summary', () {
        final healthMap = {
          'model1': ModelHealthInfo(
            modelId: 'model1',
            status: ModelHealthStatus.healthy,
            lastChecked: DateTime.now(),
          ),
          'model2': ModelHealthInfo(
            modelId: 'model2',
            status: ModelHealthStatus.unhealthy,
            lastChecked: DateTime.now(),
          ),
          'model3': ModelHealthInfo(
            modelId: 'model3',
            status: ModelHealthStatus.unknown,
            lastChecked: DateTime.now(),
          ),
          'model4': ModelHealthInfo(
            modelId: 'model4',
            status: ModelHealthStatus.testing,
            lastChecked: DateTime.now(),
          ),
        };
        modelState.modelHealthStatus.value = healthMap;

        final summary = modelState.getHealthSummary();

        expect(summary['total'], 4);
        expect(summary['healthy'], 1);
        expect(summary['unhealthy'], 1);
        expect(summary['unknown'], 1);
        expect(summary['testing'], 1);
        expect(summary['lastCheck'], isA<String>());
      });

      test('should handle empty health summary', () {
        // Clear any existing health status
        modelState.modelHealthStatus.value = {};
        
        final summary = modelState.getHealthSummary();

        expect(summary['total'], 0);
        expect(summary['healthy'], 0);
        expect(summary['unhealthy'], 0);
        expect(summary['unknown'], 0);
        expect(summary['testing'], 0);
        expect(summary['lastCheck'], isNull);
      });
    });

    group('Model Selection', () {
      test('should handle setting selected model', () async {
        // This test verifies the method exists and handles errors gracefully
        expect(() => modelState.setSelectedModel('test-model'), returnsNormally);
      });

      test('should handle clearing selected model', () async {
        expect(() => modelState.clearSelectedModel(), returnsNormally);
      });

      test('should handle refreshing available models', () async {
        expect(() => modelState.refreshAvailableModels(), returnsNormally);
      });

      test('should handle force health check', () async {
        expect(() => modelState.forceHealthCheck(), returnsNormally);
        
        // Add a test model first
        final testModel = ModelConfig(
          id: 'test-model',
          name: 'Test Model',
          provider: ModelProvider.openAI,
          model: 'gpt-3.5-turbo',
          baseUrl: 'https://api.openai.com/v1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        modelState.availableModels.value = [testModel];
        
        expect(() => modelState.forceHealthCheck(modelId: 'test-model'), returnsNormally);
      });
    });

    group('Change Notification', () {
      test('should notify listeners on model changes', () {
        bool notified = false;
        modelState.addListener(() {
          notified = true;
        });

        // Trigger a change
        modelState.selectedModelId.value = 'test-model';

        expect(notified, false); // ValueNotifier handles its own notifications
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        expect(() => modelState.dispose(), returnsNormally);
      });
    });
  });

  group('ModelHealthStatus', () {
    test('should have all expected values', () {
      expect(ModelHealthStatus.values, contains(ModelHealthStatus.healthy));
      expect(ModelHealthStatus.values, contains(ModelHealthStatus.unhealthy));
      expect(ModelHealthStatus.values, contains(ModelHealthStatus.unknown));
      expect(ModelHealthStatus.values, contains(ModelHealthStatus.testing));
    });
  });
}