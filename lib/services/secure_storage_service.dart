import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_service.dart';
import '../component/models.dart';

enum ApiKeyValidationResult {
  valid,
  invalid,
  expired,
  quotaExceeded,
  networkError,
  unknown,
}

class ApiKeyInfo {
  final String id;
  final String provider;
  final String keyHash;
  final DateTime createdAt;
  final DateTime lastUsed;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final int usageCount;

  ApiKeyInfo({
    required this.id,
    required this.provider,
    required this.keyHash,
    required this.createdAt,
    required this.lastUsed,
    this.expiresAt,
    this.metadata = const {},
    this.isActive = true,
    this.usageCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'keyHash': keyHash,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) {
    return ApiKeyInfo(
      id: json['id'],
      provider: json['provider'],
      keyHash: json['keyHash'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isActive: json['isActive'] ?? true,
      usageCount: json['usageCount'] ?? 0,
    );
  }

  ApiKeyInfo copyWith({
    String? id,
    String? provider,
    String? keyHash,
    DateTime? createdAt,
    DateTime? lastUsed,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    bool? isActive,
    int? usageCount,
  }) {
    return ApiKeyInfo(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      keyHash: keyHash ?? this.keyHash,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const String _keyPrefix = 'secure_api_key_';
  static const String _infoPrefix = 'api_key_info_';
  static const String _masterKeyKey = 'master_encryption_key';
  static const String _saltKey = 'encryption_salt';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final ErrorService _errorService = ErrorService();
  String? _masterKey;
  Uint8List? _salt;

  Future<void> initialize() async {
    try {
      await _initializeMasterKey();
      debugPrint('SecureStorageService initialized successfully');
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to initialize SecureStorageService: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'SecureStorageService.initialize',
      );
      rethrow;
    }
  }

  Future<void> _initializeMasterKey() async {
    try {
      // Try to get existing master key
      _masterKey = await _secureStorage.read(key: _masterKeyKey);
      
      if (_masterKey == null) {
        // Generate new master key
        _masterKey = _generateSecureKey();
        await _secureStorage.write(key: _masterKeyKey, value: _masterKey!);
      }

      // Initialize salt
      final saltString = await _secureStorage.read(key: _saltKey);
      if (saltString == null) {
        _salt = _generateSalt();
        await _secureStorage.write(key: _saltKey, value: base64Encode(_salt!));
      } else {
        _salt = base64Decode(saltString);
      }
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to initialize master key: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'SecureStorageService._initializeMasterKey',
      );
      rethrow;
    }
  }

  String _generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(256)));
  }

  String _encryptApiKey(String apiKey) {
    if (_masterKey == null || _salt == null) {
      throw Exception('SecureStorageService not initialized');
    }

    try {
      // Simple XOR encryption with master key (in production, use proper AES encryption)
      final keyBytes = utf8.encode(apiKey);
      final masterKeyBytes = base64Decode(_masterKey!);
      final encryptedBytes = <int>[];

      for (int i = 0; i < keyBytes.length; i++) {
        encryptedBytes.add(keyBytes[i] ^ masterKeyBytes[i % masterKeyBytes.length]);
      }

      return base64Encode(encryptedBytes);
    } catch (e, stackTrace) {
      _errorService.logError(
        'Failed to encrypt API key: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'SecureStorageService._encryptApiKey',
      );
      rethrow;
    }
  }

  String _decryptApiKey(String encryptedApiKey) {
    if (_masterKey == null || _salt == null) {
      throw Exception('SecureStorageService not initialized');
    }

    try {
      final encryptedBytes = base64Decode(encryptedApiKey);
      final masterKeyBytes = base64Decode(_masterKey!);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ masterKeyBytes[i % masterKeyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e, stackTrace) {
      _errorService.logError(
        'Failed to decrypt API key: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'SecureStorageService._decryptApiKey',
      );
      rethrow;
    }
  }

  String _hashApiKey(String apiKey) {
    final bytes = utf8.encode(apiKey + (_salt != null ? base64Encode(_salt!) : ''));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> storeApiKey({
    required String keyId,
    required String apiKey,
    required ModelProvider provider,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_masterKey == null) {
        await initialize();
      }

      // Validate API key format
      final validationResult = _validateApiKeyFormat(apiKey, provider);
      if (validationResult != ApiKeyValidationResult.valid) {
        throw Exception('Invalid API key format for ${provider.displayName}');
      }

      // Encrypt and store the API key
      final encryptedKey = _encryptApiKey(apiKey);
      await _secureStorage.write(key: '$_keyPrefix$keyId', value: encryptedKey);

      // Store API key info
      final keyInfo = ApiKeyInfo(
        id: keyId,
        provider: provider.toString(),
        keyHash: _hashApiKey(apiKey),
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
        expiresAt: expiresAt,
        metadata: metadata ?? {},
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_infoPrefix$keyId', jsonEncode(keyInfo.toJson()));

      debugPrint('API key stored successfully for ${provider.displayName}');
      return keyId;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to store API key: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.storeApiKey',
      );
      rethrow;
    }
  }

  Future<String?> getApiKey(String keyId) async {
    try {
      if (_masterKey == null) {
        await initialize();
      }

      final encryptedKey = await _secureStorage.read(key: '$_keyPrefix$keyId');
      if (encryptedKey == null) {
        return null;
      }

      final decryptedKey = _decryptApiKey(encryptedKey);
      
      // Update last used timestamp
      await _updateLastUsed(keyId);
      
      return decryptedKey;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to get API key: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.getApiKey',
      );
      return null;
    }
  }

  Future<ApiKeyInfo?> getApiKeyInfo(String keyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final infoJson = prefs.getString('$_infoPrefix$keyId');
      
      if (infoJson == null) {
        return null;
      }

      return ApiKeyInfo.fromJson(jsonDecode(infoJson));
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to get API key info: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.getApiKeyInfo',
      );
      return null;
    }
  }

  Future<List<ApiKeyInfo>> getAllApiKeyInfos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_infoPrefix));
      
      final infos = <ApiKeyInfo>[];
      for (final key in keys) {
        final infoJson = prefs.getString(key);
        if (infoJson != null) {
          try {
            infos.add(ApiKeyInfo.fromJson(jsonDecode(infoJson)));
          } catch (e) {
            debugPrint('Failed to parse API key info: $e');
          }
        }
      }

      return infos;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to get all API key infos: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.getAllApiKeyInfos',
      );
      return [];
    }
  }

  Future<bool> deleteApiKey(String keyId) async {
    try {
      // Delete encrypted key
      await _secureStorage.delete(key: '$_keyPrefix$keyId');
      
      // Delete key info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_infoPrefix$keyId');

      debugPrint('API key deleted successfully: $keyId');
      return true;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to delete API key: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.deleteApiKey',
      );
      return false;
    }
  }

  Future<void> _updateLastUsed(String keyId) async {
    try {
      final keyInfo = await getApiKeyInfo(keyId);
      if (keyInfo != null) {
        final updatedInfo = keyInfo.copyWith(
          lastUsed: DateTime.now(),
          usageCount: keyInfo.usageCount + 1,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_infoPrefix$keyId', jsonEncode(updatedInfo.toJson()));
      }
    } catch (e) {
      debugPrint('Failed to update last used timestamp: $e');
    }
  }

  ApiKeyValidationResult _validateApiKeyFormat(String apiKey, ModelProvider provider) {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.invalid;
    }

    switch (provider) {
      case ModelProvider.openAI:
        return apiKey.startsWith('sk-') && apiKey.length >= 20
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.anthropic:
        return apiKey.startsWith('sk-ant-') && apiKey.length >= 20
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.googleAI:
        return apiKey.length >= 20 && !apiKey.contains(' ')
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.mistral:
        return apiKey.length >= 20 && !apiKey.contains(' ')
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.deepseek:
        return apiKey.startsWith('sk-') && apiKey.length >= 20
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.pocketLLM:
        return apiKey.length >= 10
            ? ApiKeyValidationResult.valid
            : ApiKeyValidationResult.invalid;
            
      case ModelProvider.ollama:
      case ModelProvider.lmStudio:
        // Local providers typically don't require API keys
        return ApiKeyValidationResult.valid;
    }
  }

  Future<ApiKeyValidationResult> validateApiKey(String apiKey, ModelProvider provider) async {
    try {
      // First check format
      final formatResult = _validateApiKeyFormat(apiKey, provider);
      if (formatResult != ApiKeyValidationResult.valid) {
        return formatResult;
      }

      // For local providers, format validation is sufficient
      if (provider == ModelProvider.ollama || provider == ModelProvider.lmStudio) {
        return ApiKeyValidationResult.valid;
      }

      // TODO: Implement actual API validation by making test requests
      // This would involve making HTTP requests to each provider's API
      // For now, return valid if format is correct
      return ApiKeyValidationResult.valid;
      
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to validate API key: $e',
        stackTrace,
        type: ErrorType.validation,
        context: 'SecureStorageService.validateApiKey',
      );
      return ApiKeyValidationResult.networkError;
    }
  }

  Future<bool> rotateApiKey(String keyId, String newApiKey) async {
    try {
      final keyInfo = await getApiKeyInfo(keyId);
      if (keyInfo == null) {
        return false;
      }

      final provider = ModelProvider.values.firstWhere(
        (p) => p.toString() == keyInfo.provider,
        orElse: () => ModelProvider.openAI,
      );

      // Validate new key
      final validationResult = await validateApiKey(newApiKey, provider);
      if (validationResult != ApiKeyValidationResult.valid) {
        throw Exception('New API key validation failed');
      }

      // Store new key with updated info
      final updatedInfo = keyInfo.copyWith(
        keyHash: _hashApiKey(newApiKey),
        lastUsed: DateTime.now(),
      );

      final encryptedKey = _encryptApiKey(newApiKey);
      await _secureStorage.write(key: '$_keyPrefix$keyId', value: encryptedKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_infoPrefix$keyId', jsonEncode(updatedInfo.toJson()));

      debugPrint('API key rotated successfully: $keyId');
      return true;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to rotate API key: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.rotateApiKey',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> exportApiKeys({String? password}) async {
    try {
      final infos = await getAllApiKeyInfos();
      final exportData = <String, dynamic>{
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'keys': [],
      };

      for (final info in infos) {
        final apiKey = await getApiKey(info.id);
        if (apiKey != null) {
          exportData['keys'].add({
            'info': info.toJson(),
            'key': password != null ? _encryptWithPassword(apiKey, password) : apiKey,
          });
        }
      }

      return exportData;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to export API keys: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.exportApiKeys',
      );
      rethrow;
    }
  }

  Future<bool> importApiKeys(Map<String, dynamic> exportData, {String? password}) async {
    try {
      final keys = exportData['keys'] as List<dynamic>;
      
      for (final keyData in keys) {
        final info = ApiKeyInfo.fromJson(keyData['info']);
        final encryptedKey = keyData['key'] as String;
        final apiKey = password != null 
            ? _decryptWithPassword(encryptedKey, password)
            : encryptedKey;

        final provider = ModelProvider.values.firstWhere(
          (p) => p.toString() == info.provider,
          orElse: () => ModelProvider.openAI,
        );

        await storeApiKey(
          keyId: info.id,
          apiKey: apiKey,
          provider: provider,
          expiresAt: info.expiresAt,
          metadata: info.metadata,
        );
      }

      return true;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to import API keys: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.importApiKeys',
      );
      return false;
    }
  }

  String _encryptWithPassword(String data, String password) {
    // Simple password-based encryption (in production, use proper PBKDF2 + AES)
    final passwordBytes = utf8.encode(password);
    final dataBytes = utf8.encode(data);
    final encryptedBytes = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes.add(dataBytes[i] ^ passwordBytes[i % passwordBytes.length]);
    }

    return base64Encode(encryptedBytes);
  }

  String _decryptWithPassword(String encryptedData, String password) {
    final passwordBytes = utf8.encode(password);
    final encryptedBytes = base64Decode(encryptedData);
    final decryptedBytes = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes.add(encryptedBytes[i] ^ passwordBytes[i % passwordBytes.length]);
    }

    return utf8.decode(decryptedBytes);
  }

  Future<void> clearAllApiKeys() async {
    try {
      final infos = await getAllApiKeyInfos();
      
      for (final info in infos) {
        await deleteApiKey(info.id);
      }

      debugPrint('All API keys cleared successfully');
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to clear all API keys: $e',
        stackTrace,
        type: ErrorType.storage,
        context: 'SecureStorageService.clearAllApiKeys',
      );
      rethrow;
    }
  }
}