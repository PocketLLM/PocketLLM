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
      if (trimmedApiKey != null && trimmedApiKey.isNotEmpty) 'apiKey': trimmedApiKey,
      if (trimmedBaseUrl != null && trimmedBaseUrl.isNotEmpty) 'baseUrl': trimmedBaseUrl,
      if (metadata != null) 'metadata': metadata,
    };

    final data = await _api.post('providers/activate', body: body);
    return ProviderConnection.fromJson(Map<String, dynamic>.from(data as Map));
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
      body['apiKey'] = null;
    } else if (trimmedApiKey != null && trimmedApiKey.isNotEmpty) {
      body['apiKey'] = trimmedApiKey;
    }
    if (trimmedBaseUrl != null && trimmedBaseUrl.isNotEmpty) {
      body['baseUrl'] = trimmedBaseUrl;
    }
    if (metadata != null) {
      body['metadata'] = metadata;
    }
    if (isActive != null) {
      body['isActive'] = isActive;
    }

    final data = await _api.patch('providers/${provider.backendId}', body: body);
    return ProviderConnection.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deactivateProvider(ModelProvider provider) async {
    await _api.delete('providers/${provider.backendId}');
  }

  Future<List<ModelConfig>> getModels() async {
    final data = await _api.get('models/saved');
    final models = (data as List?) ?? [];
    return models.map((raw) => _mapModel(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<List<AvailableModelOption>> getAvailableModels({
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

    Iterable<dynamic> modelsPayload;
    if (data is List) {
      modelsPayload = data;
    } else if (data is Map) {
      final payloadMap = Map<String, dynamic>.from(data);
      final models = payloadMap['models'];
      if (models is List) {
        modelsPayload = models;
      } else if (models == null) {
        debugPrint(
          'RemoteModelService.getAvailableModels response missing "models" key: $payloadMap',
        );
        modelsPayload = const <dynamic>[];
      } else {
        throw BackendApiException(
          -1,
          'Invalid models payload received from server',
        );
      }
    } else if (data == null) {
      modelsPayload = const <dynamic>[];
    } else {
      throw BackendApiException(
        -1,
        'Unexpected response when fetching available models',
      );
    }

    return modelsPayload
        .map((entry) {
          final raw = Map<String, dynamic>.from(entry as Map);
          final providerId = raw['provider'] as String? ?? provider?.backendId ?? '';
          return AvailableModelOption.fromJson(raw, providerId);
        })
        .toList();
  }

  Future<List<ModelConfig>> importModels({
    required ModelProvider provider,
    required List<AvailableModelOption> selections,
    String? providerId,
    Map<String, dynamic>? sharedSettings,
  }) async {
    final body = {
      'provider': provider.backendId,
      if (providerId != null) 'providerId': providerId,
      'models': selections
          .map((model) => {
                'id': model.id,
                'name': model.name,
                'description': model.description,
                'metadata': model.metadata,
              })
          .toList(),
      if (sharedSettings != null) 'sharedSettings': sharedSettings,
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
    final data = await _api.get(
      'providers/${provider.backendId}/models',
      query: search != null && search.isNotEmpty ? {'search': search} : null,
    );

    final models = (data as List?) ?? [];
    return models
        .map((entry) => AvailableModelOption.fromJson(
              Map<String, dynamic>.from(entry as Map),
              provider.backendId,
            ))
        .toList();
  }

  ModelConfig _mapModel(Map<String, dynamic> json) {
    final providerDetails = json['providerDetails'] as Map<String, dynamic>?;
    final baseUrl = json['baseUrl'] as String? ??
        providerDetails?['baseUrl'] as String? ??
        ModelProviderExtension.fromBackend(json['provider']).defaultBaseUrl;

    DateTime parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ModelConfig(
      id: json['id'],
      name: json['displayName'] ?? json['name'],
      provider: ModelProviderExtension.fromBackend(json['provider']),
      providerId: json['providerId'],
      baseUrl: baseUrl,
      model: json['model'],
      systemPrompt: json['systemPrompt'],
      temperature: json['temperature'] is num ? (json['temperature'] as num).toDouble() : 0.7,
      maxTokens: json['maxTokens'] is num ? (json['maxTokens'] as num).toInt() : null,
      topP: json['topP'] is num ? (json['topP'] as num).toDouble() : 1.0,
      frequencyPenalty:
          json['frequencyPenalty'] is num ? (json['frequencyPenalty'] as num).toDouble() : 0.0,
      presencePenalty:
          json['presencePenalty'] is num ? (json['presencePenalty'] as num).toDouble() : 0.0,
      additionalParams: json['additionalParams'] != null
          ? Map<String, dynamic>.from(json['additionalParams'] as Map)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isDefault: json['isDefault'] == true,
      isActive: json['isActive'] ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
