/// File Overview:
/// - Purpose: Frontend wrapper around the backend `/providers` and `/models`
///   endpoints that keeps UI state in sync with remote model configuration.
/// - Backend Migration: Keep but slim down; this layer should become a thin
///   data access client once backend covers all provider/model logic.
import 'package:flutter/foundation.dart';
import '../component/models.dart';
import 'backend_api_service.dart';

class RemoteModelService {
  RemoteModelService._internal();
  static final RemoteModelService _instance = RemoteModelService._internal();
  factory RemoteModelService() => _instance;

  final BackendApiService _api = BackendApiService();

  Map<String, dynamic>? _castMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), v),
      );
    }
    return null;
  }

  Map<String, dynamic>? _convertSettings(Map<String, dynamic>? settings) {
    if (settings == null || settings.isEmpty) {
      return null;
    }

    final map = _castMap(settings) ?? settings;
    if (map == null || map.isEmpty) {
      return null;
    }

    final normalized = <String, dynamic>{};

    void assign(String key, dynamic value) {
      if (value != null) {
        normalized[key] = value;
      }
    }

    assign('temperature', map['temperature']);
    assign('max_tokens', map['maxTokens'] ?? map['max_tokens']);
    assign('top_p', map['topP'] ?? map['top_p']);
    assign('frequency_penalty', map['frequencyPenalty'] ?? map['frequency_penalty']);
    assign('presence_penalty', map['presencePenalty'] ?? map['presence_penalty']);
    assign('system_prompt', map['systemPrompt'] ?? map['system_prompt']);

    final metadata = map['metadata'];
    if (metadata != null) {
      normalized['metadata'] = metadata;
    }

    return normalized.isEmpty ? null : normalized;
  }

  Future<List<ProviderConnection>> getProviderConfigurations() async {
    try {
      final data = await _api.get('providers');
      final providers = (data as List?) ?? [];
      return providers
          .map((entry) => ProviderConnection.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();
    } catch (e) {
      debugPrint('RemoteModelService.getProviders error: $e');
      rethrow;
    }
  }

  Future<List<ProviderStatusInfo>> getProviderStatuses() async {
    final data = await _api.get('providers/status');
    final statuses = (data as List?) ?? [];
    return statuses
        .map((entry) => ProviderStatusInfo.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  Future<ProviderConnection> activateProvider({
    required ModelProvider provider,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final trimmedApiKey = apiKey?.trim();
    final trimmedBaseUrl = baseUrl?.trim();
    final body = {
      'provider': provider.backendId,
      if (trimmedApiKey != null && trimmedApiKey.isNotEmpty) 'api_key': trimmedApiKey,
      if (trimmedBaseUrl != null && trimmedBaseUrl.isNotEmpty) 'base_url': trimmedBaseUrl,
      if (metadata != null) 'metadata': metadata,
    };

    final data = await _api.post('providers/activate', body: body);
    return _parseProviderConnection(data);
  }

  Future<ProviderConnection> updateProvider({
    required ModelProvider provider,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? metadata,
    bool? isActive,
    bool removeApiKey = false,
  }) async {
    final body = <String, dynamic>{};
    final trimmedApiKey = apiKey?.trim();
    final trimmedBaseUrl = baseUrl?.trim();

    if (removeApiKey) {
      body['api_key'] = null;
    } else if (trimmedApiKey != null && trimmedApiKey.isNotEmpty) {
      body['api_key'] = trimmedApiKey;
    }
    if (trimmedBaseUrl != null && trimmedBaseUrl.isNotEmpty) {
      body['base_url'] = trimmedBaseUrl;
    }
    if (metadata != null) {
      body['metadata'] = metadata;
    }
    if (isActive != null) {
      body['is_active'] = isActive;
    }

    final data = await _api.patch('providers/${provider.backendId}', body: body);
    return _parseProviderConnection(data);
  }

  Future<void> deactivateProvider(ModelProvider provider) async {
    await _api.delete('providers/${provider.backendId}');
  }

  Future<List<ModelConfig>> getModels() async {
    final data = await _api.get('models/saved');
    final models = (data as List?) ?? [];
    return models.map((raw) => _mapModel(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<ModelConfig> getModelDetails(String modelId) async {
    final data = await _api.get('models/$modelId');
    final payload = _castMap(data);
    if (payload == null) {
      throw StateError('Unexpected response when fetching model details: $data');
    }
    return _mapModel(payload);
  }

  Future<AvailableModelsResponse> getAvailableModels({
    ModelProvider? provider,
    String? query,
  }) async {
    final queryParams = <String, String>{};
    if (provider != null) {
      queryParams['provider'] = provider.backendId;
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }

    final data = await _api.get(
      'models',
      query: queryParams.isEmpty ? null : queryParams,
    );

    final payloadMap = _normalizeCataloguePayload(data);
    final modelsPayload = (payloadMap['models'] as List?) ?? const <dynamic>[];
    final message = payloadMap['message'] as String?;
    final configured = _stringList(payloadMap['configured_providers']);
    final missing = _stringList(payloadMap['missing_providers']);
    final usingFallback = payloadMap['using_fallback'] == true;

    final models = modelsPayload.map((entry) {
      final raw = Map<String, dynamic>.from(entry as Map);
      final providerId = raw['provider'] as String? ?? provider?.backendId ?? '';
      return AvailableModelOption.fromJson(raw, providerId);
    }).toList();

    return AvailableModelsResponse(
      models: models,
      message: message?.trim().isEmpty ?? true ? null : message,
      configuredProviders: configured,
      missingProviders: missing,
      usingFallback: usingFallback,
    );
  }

  Map<String, dynamic> _normalizeCataloguePayload(dynamic data) {
    if (data == null) {
      return <String, dynamic>{'models': const <dynamic>[]};
    }

    if (data is List) {
      return <String, dynamic>{'models': data};
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw BackendApiException(
      -1,
      'Unexpected response when fetching available models',
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString().trim())
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  Future<List<ModelConfig>> importModels({
    required ModelProvider provider,
    required List<AvailableModelOption> selections,
    String? providerId,
    Map<String, dynamic>? sharedSettings,
  }) async {
    final normalizedSettings = _convertSettings(sharedSettings);
    final body = {
      'provider': provider.backendId,
      if (providerId != null && providerId.isNotEmpty) 'provider_id': providerId,
      'models': selections.map((model) => model.id).toList(),
      'sync': true,
      if (normalizedSettings != null) 'settings': normalizedSettings,
    };

    final data = await _api.post('models/import', body: body);
    final models = (data as List?) ?? [];
    return models.map((raw) => _mapModel(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<void> deleteModel(String modelId) async {
    await _api.delete('models/$modelId');
  }

  Future<ModelConfig> setDefaultModel(String modelId) async {
    final data = await _api.post('models/$modelId/default');
    if (data is Map) {
      return _mapModel(Map<String, dynamic>.from(data));
    }
    throw StateError('Invalid response when setting default model');
  }

  Future<List<AvailableModelOption>> getProviderModels({
    required ModelProvider provider,
    String? search,
  }) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['query'] = search.trim();
    }

    final data = await _api.get(
      'providers/${provider.backendId}/models',
      query: query.isEmpty ? null : query,
    );

    final payloadMap = _normalizeCataloguePayload(data);
    final models = (payloadMap['models'] as List?) ?? const <dynamic>[];
    return models
        .map((entry) => AvailableModelOption.fromJson(
              Map<String, dynamic>.from(entry as Map),
              provider.backendId,
            ))
        .toList();
  }

  ModelConfig _mapModel(Map<String, dynamic> json) {
    return ModelConfig.fromJson(json);
  }

  ProviderConnection _parseProviderConnection(dynamic payload) {
    final normalized = _castMap(payload);
    if (normalized == null) {
      throw StateError('Unexpected provider response: $payload');
    }

    final providerPayload = _castMap(normalized['provider']);
    if (providerPayload != null) {
      return ProviderConnection.fromJson(providerPayload);
    }

    return ProviderConnection.fromJson(normalized);
  }
}
