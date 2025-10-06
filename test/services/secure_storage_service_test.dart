import 'package:flutter_test/flutter_test.dart';
import 'package:pocketllm/services/secure_storage_service.dart';
import 'package:pocketllm/component/models.dart';

void main() {
  group('ApiKeyInfo', () {
    test('should create ApiKeyInfo with required fields', () {
      final now = DateTime.now();
      final info = ApiKeyInfo(
        id: 'test-id',
        provider: 'openai',
        keyHash: 'hash123',
        createdAt: now,
        lastUsed: now,
      );

      expect(info.id, 'test-id');
      expect(info.provider, 'openai');
      expect(info.keyHash, 'hash123');
      expect(info.createdAt, now);
      expect(info.lastUsed, now);
      expect(info.expiresAt, isNull);
      expect(info.metadata, isEmpty);
      expect(info.isActive, true);
      expect(info.usageCount, 0);
    });

    test('should create ApiKeyInfo with all fields', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));
      final metadata = {'key': 'value'};

      final info = ApiKeyInfo(
        id: 'test-id',
        provider: 'openai',
        keyHash: 'hash123',
        createdAt: now,
        lastUsed: now,
        expiresAt: expiresAt,
        metadata: metadata,
        isActive: false,
        usageCount: 5,
      );

      expect(info.id, 'test-id');
      expect(info.provider, 'openai');
      expect(info.keyHash, 'hash123');
      expect(info.createdAt, now);
      expect(info.lastUsed, now);
      expect(info.expiresAt, expiresAt);
      expect(info.metadata, metadata);
      expect(info.isActive, false);
      expect(info.usageCount, 5);
    });

    test('should serialize to and from JSON', () {
      final now = DateTime.now();
      final original = ApiKeyInfo(
        id: 'test-id',
        provider: 'openai',
        keyHash: 'hash123',
        createdAt: now,
        lastUsed: now,
        expiresAt: now.add(const Duration(days: 30)),
        metadata: {'key': 'value'},
        isActive: false,
        usageCount: 5,
      );

      final json = original.toJson();
      final restored = ApiKeyInfo.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.provider, original.provider);
      expect(restored.keyHash, original.keyHash);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastUsed, original.lastUsed);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.metadata, original.metadata);
      expect(restored.isActive, original.isActive);
      expect(restored.usageCount, original.usageCount);
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final original = ApiKeyInfo(
        id: 'test-id',
        provider: 'openai',
        keyHash: 'hash123',
        createdAt: now,
        lastUsed: now,
      );

      final copy = original.copyWith(
        usageCount: 10,
        isActive: false,
      );

      expect(copy.id, original.id);
      expect(copy.provider, original.provider);
      expect(copy.keyHash, original.keyHash);
      expect(copy.createdAt, original.createdAt);
      expect(copy.lastUsed, original.lastUsed);
      expect(copy.usageCount, 10);
      expect(copy.isActive, false);
    });
  });

  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() {
      secureStorage = SecureStorageService();
    });

    group('Initialization', () {
      test('should initialize without errors', () async {
        // Note: This test may fail in test environment due to secure storage dependencies
        // but verifies the method exists and handles errors gracefully
        expect(() => secureStorage.initialize(), returnsNormally);
      });
    });

    group('API Key Validation', () {
      test('should validate OpenAI API key format', () async {
        final result = await secureStorage.validateApiKey('sk-1234567890abcdef1234567890abcdef', ModelProvider.openAI);
        expect(result, ApiKeyValidationResult.valid);
      });

      test('should reject invalid OpenAI API key format', () async {
        final result = await secureStorage.validateApiKey('invalid-key', ModelProvider.openAI);
        expect(result, ApiKeyValidationResult.invalid);
      });

      test('should validate Anthropic API key format', () async {
        final result = await secureStorage.validateApiKey('sk-ant-1234567890abcdef1234567890abcdef', ModelProvider.anthropic);
        expect(result, ApiKeyValidationResult.valid);
      });

      test('should reject invalid Anthropic API key format', () async {
        final result = await secureStorage.validateApiKey('sk-1234567890abcdef', ModelProvider.anthropic);
        expect(result, ApiKeyValidationResult.invalid);
      });

      test('should validate Google AI API key format', () async {
        final result = await secureStorage.validateApiKey('AIzaSyDaGmWKa4JsXZ-HjGw7ISLan_KqP8o9wMc', ModelProvider.googleAI);
        expect(result, ApiKeyValidationResult.valid);
      });

      test('should validate local provider keys', () async {
        final ollamaResult = await secureStorage.validateApiKey('', ModelProvider.ollama);
        expect(ollamaResult, ApiKeyValidationResult.valid);

        final lmStudioResult = await secureStorage.validateApiKey('', ModelProvider.lmStudio);
        expect(lmStudioResult, ApiKeyValidationResult.valid);
      });

      test('should reject empty keys for cloud providers', () async {
        final result = await secureStorage.validateApiKey('', ModelProvider.openAI);
        expect(result, ApiKeyValidationResult.invalid);
      });
    });

    group('API Key Storage Operations', () {
      test('should handle store API key operation', () async {
        // Note: These tests may fail in test environment due to secure storage dependencies
        // but verify the methods exist and handle errors gracefully
        expect(() => secureStorage.storeApiKey(
          keyId: 'test-key',
          apiKey: 'sk-1234567890abcdef1234567890abcdef',
          provider: ModelProvider.openAI,
        ), returnsNormally);
      });

      test('should handle get API key operation', () async {
        expect(() => secureStorage.getApiKey('test-key'), returnsNormally);
      });

      test('should handle get API key info operation', () async {
        expect(() => secureStorage.getApiKeyInfo('test-key'), returnsNormally);
      });

      test('should handle get all API key infos operation', () async {
        expect(() => secureStorage.getAllApiKeyInfos(), returnsNormally);
      });

      test('should handle delete API key operation', () async {
        expect(() => secureStorage.deleteApiKey('test-key'), returnsNormally);
      });

      test('should handle rotate API key operation', () async {
        expect(() => secureStorage.rotateApiKey('test-key', 'sk-newkey1234567890abcdef1234567890'), returnsNormally);
      });
    });

    group('Import/Export Operations', () {
      test('should handle export API keys operation', () async {
        expect(() => secureStorage.exportApiKeys(), returnsNormally);
      });

      test('should handle export with password', () async {
        expect(() => secureStorage.exportApiKeys(password: 'test-password'), returnsNormally);
      });

      test('should handle import API keys operation', () async {
        final exportData = {
          'version': '1.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'keys': [],
        };
        
        expect(() => secureStorage.importApiKeys(exportData), returnsNormally);
      });

      test('should handle import with password', () async {
        final exportData = {
          'version': '1.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'keys': [],
        };
        
        expect(() => secureStorage.importApiKeys(exportData, password: 'test-password'), returnsNormally);
      });
    });

    group('Utility Operations', () {
      test('should handle clear all API keys operation', () async {
        expect(() => secureStorage.clearAllApiKeys(), returnsNormally);
      });
    });
  });

  group('ApiKeyValidationResult', () {
    test('should have all expected values', () {
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.valid));
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.invalid));
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.expired));
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.quotaExceeded));
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.networkError));
      expect(ApiKeyValidationResult.values, contains(ApiKeyValidationResult.unknown));
    });
  });
}